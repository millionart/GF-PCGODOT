# PCGODOT (Flow Graph)

[![Godot Engine](https://img.shields.io/badge/Godot-%23FFFFFF.svg?style=flat&logo=godot-engine&logoColor=cyan)](https://godotengine.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

**PCGODOT** is a highly powerful, node-based Procedural Content Generation (PCG) framework for Godot 4.6+, heavily inspired by advanced node-based procedural workflows. It enables developers to construct intricate point-set distributions, manipulate spatial attributes, and spawn meshes, lights, or scene hierarchies procedurally using a visual flow graph editor inside Godot.

ℹ️ **Project Origin & Fork Information**:  
This project is a fork and feature-rich expansion of the original **[flownode](https://github.com/miskatonicstudio/flownode)** plugin. It has been significantly upgraded and polished with new features, tools, and QoL enhancements to make it a more comprehensive editor tool:
* **Interactive 3D Viewport Debugging**: Toggle node visualizations directly inside the 3D editor (using the **`D`** key) to see exactly where points are spawning.
* **Searchable Data Inspector**: An attribute table spreadsheet panel (using the **`E`** key) with live text-filtering and cross-highlighting (selecting a row highlights the target point in Magenta in the 3D viewport).
* **Auto-Reload Graph Cache**: Real-time monitoring of `.tres` graph files to invalidate editor caches and hot-reload changes instantly.
* **Over 110 Nodes**: A substantially expanded node library including math expressions, spline/polygon clipping, physics queries, and layout generators.
* **Precompiled Binaries**: Bundled GDExtension libraries for Windows and macOS.

![PCGODOT Flow Editor](demo/addons/flow_nodes_editor/doc/demo_flashy_colonnade_ui.png)

---

## 🚀 Key Features

* **Standardized Node Structure**: Unified categories, clear names, and consistent logical schemas.
* **+110 Nodes**: A robust library of nodes for spatial, attribute, and asset generation. Check out the full [PCGODOT Node Library Reference](demo/addons/flow_nodes_editor/doc/nodes_reference.md).
* **Interactive 3D Viewport Debugging**: Toggle 3D visualizations showing point positions, density gradients, scale, and rotations directly in Godot's editor (select a node and press **`D`**).
* **Searchable Data Inspector**: Spreadsheet/table inspector showcasing attributes at any node, with active highlighting linked back to the 3D viewport (select a node and press **`E`**).
* **Subgraphs & Loops**: Nest graphs with local parameters, custom outputs, and feedback loops.
* **Core Tagging Support**: A dedicated `tags` property (`PackedStringArray`) inside data elements for tag-based filtering.
* **Copy/Paste**: Import/export graph components instantly as JSON.
* **Auto-Reload Pipeline**: Automatically monitors filesystem changes, invalidates caches, and hot-reloads graphs in the editor.

---

## 📂 Node Library Reference

PCGODOT organizes nodes into a clean category structure, expanded with custom Godot helpers. For detailed documentation on what each node does and to view their source code, see the **[PCGODOT Node Library Reference](demo/addons/flow_nodes_editor/doc/nodes_reference.md)**.

### 📁 Category Overview:
1. **Subgraphs & Control Flow**: Nested subgraphs (`subgraph.gd`), loops (`loop.gd`), inputs/outputs, branches, select nodes, and conditional switches.
2. **Metadata & Attributes**: Add/remove attributes, rename streams, filter attribute ranges, and manipulate tag collections.
3. **Math & Logic Ops**: Standard math operations (`math_op.gd`), curve/density remapping, custom expression parser (`expression.gd`), and aggregate reductions.
4. **Splines & Paths**: Sample spline paths, generate splines from point arrays, calculate distance gradients, and clip points by boundary polygons.
5. **Point Transformations**: Move, rotate, scale, and snap points to grid boundaries, prune overlaps (`self_pruning.gd`), or apply Lloyd relaxation.
6. **Assets & Spawning**: Spawn MultiMeshes, scene instances (`spawn_scenes.gd`), lights/GI nodes (`spawn_nodes.gd`), or apply point data properties to actors.
7. **Spatial & Physics Queries**: Perform spatial difference/intersection/union operations, trace raycasts, or check for physics collisions.
8. **Generators & Grid Nodes**: Draw coordinate grids, extract edge/corner boundaries, generate simplex noise, and build room-carving layouts.

---

## 🎨 Gallery & Showcases

### 1. Sampling Meshes (Discarding Hard Edges)
Distribute points across the faces of a 3D Mesh while pruning points near hard edges.
![Sampling Mesh](demo/addons/flow_nodes_editor/doc/demo_sample_mesh.png)

### 2. Random Subscenes Distribution (Forests & Paths)
Distribute different subscenes randomly along curves and paths using attributes, custom rotation-alignment filters, and scene scanners.
![Random Subscenes](demo/addons/flow_nodes_editor/doc/demo_random_subscenes.png)

### 3. Unified Filters & Category Popup
Browse nodes structured into standardized categories. Select filters such as `Filter Data by Attribute`, `Filter Data by Tag`, and `Filter Data by Type`.
![Filters](demo/addons/flow_nodes_editor/doc/demo_filter.png)

### 4. Proximity Sampling & Distance to Density
Sample points and scale their density values smoothly based on their distance/proximity to curves or splines.
![Distance to Density](demo/addons/flow_nodes_editor/doc/demo_distance.png)

### 5. Nested Subgraphs & Selection Collapse
Create nested graphs and easily collapse selected nodes into a reusable Subgraph.
![Subgraph Collapse](demo/addons/flow_nodes_editor/doc/demo_subgraph_popup.png)

### 6. Procedural Helical Colonnade & Rubble Scatter
Generate complex procedural architecture such as helical towers. Combines curve sampling with coordinate transforms, relative lintel placement, and duplicate scatter operations to create debris and rubble.
![Helical Colonnade](demo/addons/flow_nodes_editor/doc/demo_flashy_colonnade_v2.png)

### 7. Fall Guys Hexagons
Generate dynamic gameplay platforms such as the multi-colored hexagon grid inspired by Fall Guys. Use the **Random Color** node to assign random color attributes from a palette to a MultiMesh.
![Fall Guys Hexagons](demo/addons/flow_nodes_editor/doc/demo_spawn_nodes_v2.png)

---

## 🛠️ Setup & Installation

1. Copy the following folders from this repository into your Godot project's root:
   * `demo/addons/flow_nodes_editor`
   * `demo/bin`
2. Open your project in Godot: **Project** → **Project Settings** → **Plugins**.
3. Locate **Flow Nodes Editor** and toggle the status to **Enabled**.

---

## 🎮 Quickstart Guide

In a 3D Scene:
1. Create a `FlowGraphNode3D` node.
2. In the bottom dock panel, select the **Data Flow** workspace (appears when the node is selected).
3. Press **Shift+A** (or **Right-click**) inside the graph to open the **Add Node** search panel.
4. Add a generator like **Grid**, then connect it to **Spawn Scenes** or **Spawn Meshes**.
5. Press **D** on a selected node to toggle its 3D debug visualizer.
6. Press **E** to toggle the bottom **Data Inspector** spreadsheet.

---

## 🏗️ Building from Sources

If you want to compile the C++ wrappers (KdTree, RTree) yourself:

```bash
git submodule update --init
scons
```
Precompiled binaries for Windows and macOS are included under `demo/bin/` by default.

---

## 📄 License
This project is licensed under the Apache License 2.0. Feel free to adapt and expand it!
