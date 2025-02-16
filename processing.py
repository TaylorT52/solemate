import tempfile
import os
import open3d as o3d
import numpy as np
import trimesh
from trimesh.smoothing import filter_laplacian
import shutil
import cv2

# --- Your generate_mesh function using Open3D ---
def generate_mesh(file_name):
    pcd = o3d.io.read_point_cloud(file_name)

    # Densify the point cloud by voxel downsampling
    pcd = pcd.voxel_down_sample(voxel_size=0.002)  # Smaller voxel = denser cloud

    # Estimate normals
    pcd.estimate_normals(search_param=o3d.geometry.KDTreeSearchParamHybrid(radius=0.05, max_nn=50))

    # Expand each point using its normal to create a denser cloud
    new_points = []
    for point, normal in zip(np.asarray(pcd.points), np.asarray(pcd.normals)):
        for i in range(20):  # Increase density significantly
            new_points.append(point + normal * (0.001 * np.random.randn()))
    all_points = np.vstack((np.asarray(pcd.points), np.array(new_points)))
    pcd.points = o3d.utility.Vector3dVector(all_points)

    # Re-estimate normals after densification
    pcd.estimate_normals(search_param=o3d.geometry.KDTreeSearchParamHybrid(radius=0.1, max_nn=30))
    pcd.orient_normals_consistent_tangent_plane(k=50)

    # Define alpha for Alpha Shape Reconstruction
    alpha = 0.01
    tetra_mesh, pt_map = o3d.geometry.TetraMesh.create_from_point_cloud(pcd)
    mesh = o3d.geometry.TriangleMesh.create_from_point_cloud_alpha_shape(pcd, alpha, tetra_mesh, pt_map)

    # Apply Laplacian smoothing to reduce sharp triangles and smooth the mesh
    mesh = mesh.filter_smooth_laplacian(number_of_iterations=10)
    mesh.compute_vertex_normals()

    # Create a temporary file for the OBJ
    with tempfile.NamedTemporaryFile(suffix=".obj", delete=False) as tmp:
        obj_path = tmp.name

    o3d.io.write_triangle_mesh(obj_path, mesh)
    print(f"Generated mesh saved to temporary file: {obj_path}")
    return obj_path

def invert_mesh(input_obj, output_obj=None):
    """
    Invert a convex mesh by reflecting its vertices about its centroid.
    
    If no output_obj is provided, a temporary file is created and its path is returned.
    
    This effectively “inverts” the shape:
      - For a convex sole, it turns the outside into an inside cavity.
      - Note: This does not create a cavity inside a block but simply flips the geometry.
    """
    # If no output path is provided, create a temporary file.
    if output_obj is None:
        with tempfile.NamedTemporaryFile(suffix=".obj", delete=False) as tmp:
            output_obj = tmp.name

    # Load the input mesh.
    mesh = trimesh.load(input_obj)
    
    # Compute the centroid of the mesh.
    center = mesh.centroid
    
    # Reflect each vertex about the centroid:
    # new_vertex = center - (old_vertex - center) = 2*center - old_vertex
    inverted_vertices = 2 * center - mesh.vertices
    
    # Create a new mesh with the inverted vertices and same faces.
    inverted_mesh = trimesh.Trimesh(vertices=inverted_vertices, faces=mesh.faces)
    
    # Optionally, invert the face winding so normals point inward.
    inverted_mesh.invert()
    
    # Export the inverted mesh.
    inverted_mesh.export(output_obj)
    print("Inverted mesh saved to", output_obj)
    return output_obj

def project_point(point, intrinsics, extrinsics=np.eye(4)):
    # Convert the 3D point to homogeneous coordinates
    p_homog = np.append(point, 1)
    # Transform into camera coordinates (if extrinsics are provided)
    p_cam = extrinsics @ p_homog
    x, y, z, _ = p_cam
    if z == 0:
        return None
    # Apply pinhole camera model: u = fx*(x/z) + cx, v = fy*(y/z) + cy
    u = intrinsics[0, 0] * (x / z) + intrinsics[0, 2]
    v = intrinsics[1, 1] * (y / z) + intrinsics[1, 2]
    return np.array([u, v]), z

def refine_mesh_with_image(mesh, mask, intrinsics, extrinsics=np.eye(4), step_size=0.001, iterations=10):
    h, w = mask.shape
    # Pre-compute a distance transform from the inverted mask: pixels outside the foot have high distance.
    dist_transform = cv2.distanceTransform(255 - mask, cv2.DIST_L2, 5)

    vertices = mesh.vertices.copy()

    for iter in range(iterations):
        new_vertices = vertices.copy()
        for i, vertex in enumerate(vertices):
            proj, depth = project_point(vertex, intrinsics, extrinsics)
            if proj is None:
                continue
            u, v = proj
            u_int, v_int = int(round(u)), int(round(v))
            # Skip if projection is outside the image bounds
            if u_int < 0 or u_int >= w or v_int < 0 or v_int >= h:
                continue
            # Use the distance transform to decide if the point is outside the silhouette.
            distance = dist_transform[v_int, u_int]
            # If the distance is above a threshold, adjust the vertex along the ray direction
            if distance > 1.0:  # threshold (adjust as needed)
                # Compute a direction vector from the camera center through the vertex.
                p_cam = extrinsics @ np.append(vertex, 1)
                direction = p_cam[:3] / np.linalg.norm(p_cam[:3])
                # Move the vertex a small step along the negative of this direction (bringing it closer)
                new_vertices[i] = vertex - step_size * direction
        vertices = new_vertices  # update vertices for the next iteration
    # Update mesh with refined vertices
    mesh.vertices = vertices
    return mesh

def final_and_smooth(input_obj):
    mesh = trimesh.load(input_obj)

    # Load and segment your foot image (here we assume a pre-segmented mask)
    mask = cv2.imread("/Users/taylortam/Desktop/samples/IMG_0001.jpg", cv2.IMREAD_GRAYSCALE)
    if mask is None:
        raise ValueError("Could not load segmentation mask.")

    # Define your camera intrinsics (example values – adjust as needed)
    fx, fy = 600, 600
    cx, cy = mask.shape[1] / 2, mask.shape[0] / 2
    intrinsics = np.array([[fx,   0, cx],
                        [  0, fy, cy],
                        [  0,  0,  1]])
    # Optionally, define extrinsics if your mesh is in a different coordinate system.

    # Refine the mesh using the image segmentation
    refined_mesh = refine_mesh_with_image(mesh, mask, intrinsics, iterations=20)

    # Apply Laplacian smoothing to the refined mesh to further improve smoothness.
    filter_laplacian(refined_mesh, lamb=0.5, iterations=20)

    # Create a temporary file path for the output OBJ file.
    with tempfile.NamedTemporaryFile(suffix=".obj", delete=False) as tmp:
        output_path = tmp.name

    # Save the refined, smoothed mesh to the temporary file.
    refined_mesh.export(output_path)
    print("Refined and smoothed mesh saved to", output_path)
    return output_path

temp_mesh_path = generate_mesh("/Users/taylortam/Desktop/exported.ply")
inverted_temp_path = invert_mesh(temp_mesh_path)

final = final_and_smooth(inverted_temp_path)

# Define destination path
destination_path = "/Users/taylortam/Desktop/final.obj"

# Copy the processed file to the destination
shutil.copy(final, destination_path)