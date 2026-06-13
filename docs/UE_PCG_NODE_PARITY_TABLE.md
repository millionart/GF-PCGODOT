# UE PCG / Flow Editor Node Parity Table

Generated from local UE PCG source path: `\\NAS\Downloads\UnrealEngine\Engine\Plugins\PCG\Source`.

This is a node-name coverage table, not a full semantic audit. A row marked `已有` means a Flow node title or alias matches the UE PCG node title or UE title alias extracted from source; behavior can still be partial and should be audited before claiming strict parity for that node.

## Extraction Scope

- UE nodes: `GetDefaultNodeTitle()`, `GetNodeTitleAliases()`, plus `GetPreconfiguredInfo()` titles found under `PCG/Source`, with manual additions for graph infrastructure and constant-return title nodes (`Input`, `Output`, `Reroute`, `Subgraph`, `Add Attribute`, `Create Constant`, `Select (Multi)`, `Switch`).
- Flow nodes: `demo/addons/flow_nodes_editor/nodes/*.gd`, excluding `*_settings.gd`, using each node metadata `title` and `aliases`.
- Status values: `已有` = title/alias match exists; `缺失` = no Flow title/alias match found.

## Summary

| Metric | Count |
|---|---:|
| UE PCG node titles extracted | 221 |
| Matched by Flow title or alias | 91 |
| Missing from Flow title or alias | 130 |
| Flow node titles scanned | 126 |
| Flow-only / non-UE-direct nodes | 39 |

## Manual Fuzzy Review

After fuzzy title matching plus source/input-output/function review, these Flow nodes were renamed to UE titles because their core function is close enough to the UE node family: `Apply On Object`, `Attribute Boolean Op`, `Break Vector Attribute`, `Make Vector Attribute`, `Create Surface From Polygon2D`, `Attribute Curve Remap`, and `Get Element Count`. Godot-only scene/source helpers, convenience nodes, narrower partial nodes, and project-specific nodes remain listed as Flow-only.

## Semantic Audit Of The 91 Matched Rows

The 91 `已有` rows were reviewed beyond title matching. This section records whether the Flow node is a strict-enough functional match, a partial implementation, or a Godot-side substitute for a UE-world concept.

Status legend:

- `Close`: core behavior is covered in Flow's data model; no obvious parity gap found in this audit.
- `Patched`: a concrete gap was found and fixed in this pass.
- `Partial`: same node family, but UE has settings, modes, or data types that Flow does not yet cover.
- `Substitute`: useful Godot equivalent, but not a strict UE PCG implementation because UE APIs/world data do not exist here.
- `Graph`: graph/editor infrastructure rather than a PCG element behavior match.

Patched in this pass:

| UE PCG node | Flow node | Status | Notes |
|---|---|---|---|
| `Attribute Curve Remap` | `Attribute Curve Remap` | Patched / Partial | Now supports Float, Int, Vector, and Color streams component-wise with N:1 broadcast. Still lacks UE `Attribute Remap` range mode and UE-only Vector2/Vector4/Rotator/Quat types. |
| `Break Vector Attribute` | `Break Vector Attribute` | Patched / Partial | Now emits W and supports Color as a four-component Flow value; Vector3 W is 0. Flow still has no UE Vector2/Vector4/Rotator/Quat data types. |
| `Density Remap` | `Density Remap` | Patched / Partial | Now reads broadcast `$Density` streams safely. It remains a focused density preconfiguration, not the full UE `Attribute Remap` range node. |

Close enough under Flow's current data model:

`Add Attribute`, `Add Tags`, `Attribute Boolean Op`, `Attribute Filter`, `Attribute Filter Range`, `Attribute Partition`, `Attribute Reduce`, `Attribute Rename`, `Attribute Set To Point`, `Branch`, `Create Constant`, `Data Count`, `Data Table Row To Attribute Set`, `Debug`, `Delete Attributes`, `Delete Tags`, `Density Filter`, `Duplicate Point`, `Extract Attribute at Index`, `Filter Data By Attribute`, `Filter Data By Index`, `Filter Data By Tag`, `Filter Data By Type`, `Get Attribute From Point Index`, `Get Element Count`, `Get Loop Index`, `Load Data Table`, `Load PCG Data Asset`, `Match And Set Attributes`, `Mutate Seed`, `Normal To Density`, `Point To Attribute Set`, `Print String`, `Replace Tags`, `Select`, `Select (Multi)`, `Sort Attributes`, `Switch`.

Partial matches that should not be claimed as full UE parity yet:

| UE PCG node | Flow node | Main gap |
|---|---|---|
| `Attribute Maths Op` | `Math` | Numeric-focused subset; UE metadata math has broader type/operator coverage. |
| `Attribute Noise` / `Density Noise` | `Attribute Noise` | Numeric attribute noise is present; UE has additional metadata typing/details. |
| `Bounds Modifier` | `Bounds Modifier` | Point bounds mutation exists; UE bounds/extent semantics are not exhaustively mirrored. |
| `Clip Paths` | `Clip Paths` | Path clipping exists; UE polygon/path data compatibility is not exhaustive. |
| `Combine Points` | `Combine Points` | Core point combination exists; UE per-point property rules should be audited before strict parity claims. |
| `Copy Points` | `Copy Points` | Core copy behavior exists; UE copy inheritance and matching settings are broader. |
| `Create Points` / `Create Points Grid` | `Grid` | Grid point generation exists; UE Create Points and Create Points Grid are broader node families. |
| `Create Spline` | `Create Spline` | Godot `Path3D` output approximates UE spline creation; spline metadata/details differ. |
| `Create Surface From Polygon2D` | `Create Surface From Polygon2D` | Flow produces a Godot/Flow surface representation, not UE polygon surface data. |
| `Create Surface From Spline` | `Create Surface From Spline` | Godot spline surface approximation; not UE surface data. |
| `Difference` | `Difference` | Spatial boolean behavior exists; exact UE density/bounds tagging rules need deeper audit. |
| `Distance` | `Distance` | Distance attributes exist; UE distance modes/settings are broader. |
| `Filter Attribute Elements` | `Filter` | Numeric/bool filtering and constant/broadcast paths exist; UE supports more attribute types and edge cases. |
| `Get Bounds` | `Make Bounds` | Flow computes bounds-like data; UE bounds data model differs. |
| `Intersection` | `Intersection` | Spatial intersection exists; exact UE density/data behavior is not fully mirrored. |
| `Loop` | `Loop` | Looping exists; UE loop execution/context details are broader. |
| `Make Vector Attribute` | `Make Vector Attribute` | Vector3 construction exists; UE also supports Vector2/Vector4-related variants. |
| `Merge Points` | `Merge` / `Merge Points` | Merge exists; UE data merge policies have more detail. |
| `Point Filter` / `Point Filter Range` | `Point Filter Range` | Range filtering exists; UE point filter has additional type/property coverage. |
| `Point From Mesh` | `Point From Mesh` | Godot mesh point extraction, not UE static mesh data. |
| `Point Neighborhood` | `Point Neighborhood` | Neighborhood attributes exist; UE settings/output details should be audited before strict parity. |
| `Polygon Operation` | `Polygon Operation` | Polygon operations exist; UE polygon data model differs. |
| `Projection` | `Projection` | Projection exists; exact UE projection data behavior is broader. |
| `Sanity Check Point Data` | `Sanity Check Point Data` | Basic validation exists; UE checks and diagnostics are broader. |
| `Select Points` | `Select Points` | Selection exists; UE weighted/random selection settings are broader. |
| `Self Pruning` | `Self Pruning` | Pruning exists; UE pruning modes/details are broader. |
| `Spatial Noise` | `Spatial Noise` | Perlin2D/Caustic2D/FractionalBrownian2D basics exist; Voronoi2D, EdgeMask2D, and tiling are still incomplete. |
| `Spline Sampler` | `Sample Spline` | Sampling exists; UE spline sampler exposes more dimension/fill/property options. |
| `Spline to Segment` | `Spline to Segment` | Segment extraction exists; UE spline metadata compatibility still needs audit. |
| `Surface Sampler` | `Surface Sampler` | Sampling exists; UE surface data and sampling controls are broader. |
| `Transform Points` | `Transform Points` | Point transform exists; UE transform inheritance/randomization details may be broader. |
| `Union` | `Union` | Spatial union exists; exact UE data semantics need audit. |
| `Volume Sampler` | `Volume Sampler` | Sampling exists; UE volume data model differs. |

Godot substitutes for UE-world features:

| UE PCG node | Flow node | Reason |
|---|---|---|
| `Apply On Object` | `Apply On Object` | Uses Godot object/resource/property conventions instead of UE UObject/Actor property overrides and post-process functions. |
| `Get Actor Data` | `Points From Scene` / `Scan Nodes` | Scans Godot scene nodes, not UE actors. |
| `Get Landscape Data` | `Scan Meshes` | Godot mesh scan substitute; no UE Landscape data model. |
| `Get Primitive Data` | `Scan Meshes` | Godot primitive/mesh substitute. |
| `Get Spline Data` | `Scan Splines` | Godot `Path3D`/spline substitute. |
| `Get Texture Data` | `Texture Sampler` | Texture sampling exists, but not UE texture data. |
| `Spawn Actor` | `Spawn Scenes` | Godot scene instancing substitute for UE actor spawning. |
| `Static Mesh Spawner` | `Spawn Meshes` | Godot mesh/node spawning substitute for UE static mesh spawning. |
| `World Ray Hit Query` | `Ray Cast` | Godot physics ray query substitute. |
| `World Volumetric Query` | `Physics Overlap Query` | Godot physics overlap substitute. |

Graph/editor infrastructure rows:

`Input`, `Output`, `Reroute`, `Subgraph`.

## UE PCG Nodes

| UE PCG node | UE aliases | Status | Flow node | Flow file | UE source | Source kind |
|---|---|---|---|---|---|---|
| `Add Attribute` | - | 已有 | `Add Attribute` | `demo/addons/flow_nodes_editor/nodes/add_attribute.gd` | `PCG/Private/Elements/PCGCreateAttribute.cpp` | manual constant title |
| `Add Complex Constant` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGCreateComplexConstantElement.cpp` | default title |
| `Add Component` | - | 缺失 | - | - | `PCG/Public/Elements/PCGAddComponent.h` | default title |
| `Add Tags` | - | 已有 | `Add Tags` | `demo/addons/flow_nodes_editor/nodes/add_tags.gd` | `PCG/Public/Elements/PCGAddTag.h` | default title |
| `Align Points` | - | 缺失 | - | - | `PCG/Private/Elements/PCGAlignPoints.cpp` | default title |
| `Apply Hierarchy` | - | 缺失 | - | - | `PCG/Public/Elements/PCGApplyHierarchy.h` | default title |
| `Apply On Object` | - | 已有 | `Apply On Object` | `demo/addons/flow_nodes_editor/nodes/apply_on_actor.gd` | `PCG/Public/Elements/PCGApplyOnActor.h` | default title |
| `Apply Scale To Bounds` | - | 缺失 | - | - | `PCG/Public/Elements/PCGApplyScaleToBounds.h` | default title |
| `Apply Spline To Component` | - | 缺失 | - | - | `PCG/Internal/Elements/Editor/PCGApplySplineToComponent.h` | default title |
| `Attract` | - | 缺失 | - | - | `PCG/Public/Elements/PCGAttractElement.h` | default title |
| `Attribute Bitwise Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataBitwiseOpElement.cpp` | default title |
| `Attribute Boolean Op` | - | 已有 | `Attribute Boolean Op` | `demo/addons/flow_nodes_editor/nodes/boolean.gd` | `PCG/Private/Elements/Metadata/PCGMetadataBooleanOpElement.cpp` | default title |
| `Attribute Cast` | - | 缺失 | - | - | `PCG/Public/Elements/Metadata/PCGAttributeCast.h` | default title |
| `Attribute Compare Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataCompareOpElement.cpp` | default title |
| `Attribute Curve Remap` | - | 已有 | `Attribute Curve Remap` | `demo/addons/flow_nodes_editor/nodes/remap.gd` | `PCG/Private/Elements/PCGAttributeRemap.cpp` | preconfigured title |
| `Attribute Filter` | - | 已有 | `Attribute Filter Range` | `demo/addons/flow_nodes_editor/nodes/attribute_filter_range.gd` | `PCG/Private/Elements/PCGAttributeFilter.cpp` | preconfigured title |
| `Attribute Filter Range` | - | 已有 | `Attribute Filter Range` | `demo/addons/flow_nodes_editor/nodes/attribute_filter_range.gd` | `PCG/Private/Elements/PCGAttributeFilter.cpp` | preconfigured title |
| `Attribute Maths Op` | - | 已有 | `Math` | `demo/addons/flow_nodes_editor/nodes/math_op.gd` | `PCG/Private/Elements/Metadata/PCGMetadataMathsOpElement.cpp` | default title |
| `Attribute Noise` | - | 已有 | `Attribute Noise` | `demo/addons/flow_nodes_editor/nodes/attribute_noise.gd` | `PCG/Public/Elements/PCGAttributeNoise.h` | default title |
| `Attribute Partition` | - | 已有 | `Partition` | `demo/addons/flow_nodes_editor/nodes/partition.gd` | `PCG/Public/Elements/Metadata/PCGMetadataPartition.h` | default title |
| `Attribute Reduce` | - | 已有 | `Reduce` | `demo/addons/flow_nodes_editor/nodes/reduce.gd` | `PCG/Private/Elements/PCGAttributeReduceElement.cpp` | default title |
| `Attribute Remap` | - | 缺失 | - | - | `PCG/Private/Elements/PCGAttributeRemap.cpp` | default title |
| `Attribute Remove Duplicates` | - | 缺失 | - | - | `PCG/Public/Elements/PCGAttributeRemoveDuplicates.h` | default title |
| `Attribute Rename` | - | 已有 | `Attribute Rename` | `demo/addons/flow_nodes_editor/nodes/attribute_rename.gd` | `PCG/Public/Elements/Metadata/PCGMetadataRenameElement.h` | default title |
| `Attribute Rotator Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataRotatorOpElement.cpp` | default title |
| `Attribute Select` | - | 缺失 | - | - | `PCG/Private/Elements/PCGAttributeSelectElement.cpp` | default title |
| `Attribute Set To Point` | - | 已有 | `Attribute Set To Point` | `demo/addons/flow_nodes_editor/nodes/attribute_set_to_point.gd` | `PCG/Public/Elements/PCGCollapseElement.h` | default title |
| `Attribute String Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataStringOpElement.cpp` | default title |
| `Attribute Transform Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataTransformOpElement.cpp` | default title |
| `Attribute Trig Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataTrigOpElement.cpp` | default title |
| `Attribute Vector Op` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataVectorOpElement.cpp` | default title |
| `Bake Static Mesh Attributes` | - | 缺失 | - | - | `PCG/Private/Elements/PCGBakeStaticMeshAttributes.cpp` | default title |
| `Blur` | - | 缺失 | - | - | `PCG/Private/Elements/PCGBlurElement.cpp` | default title |
| `Bounds From Mesh` | - | 缺失 | - | - | `PCG/Private/Elements/PCGBoundsFromMesh.cpp` | default title |
| `Bounds Modifier` | - | 已有 | `Bounds Modifier` | `demo/addons/flow_nodes_editor/nodes/bounds_modifier.gd` | `PCG/Public/Elements/PCGBoundsModifier.h` | default title |
| `Branch` | - | 已有 | `Branch` | `demo/addons/flow_nodes_editor/nodes/branch.gd` | `PCG/Private/Elements/ControlFlow/PCGBranch.cpp` | default title |
| `Break Transform Attribute` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataBreakTransform.cpp` | default title |
| `Break Vector Attribute` | - | 已有 | `Break Vector Attribute` | `demo/addons/flow_nodes_editor/nodes/decompose_vector.gd` | `PCG/Private/Elements/Metadata/PCGMetadataBreakVector.cpp` | default title |
| `Change Grid Size` | - | 缺失 | - | - | `PCG/Private/Elements/PCGHiGenGridSize.cpp` | default title |
| `Clean Spline` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCleanSpline.h` | default title |
| `Clip Paths` | - | 已有 | `Clip Paths` | `demo/addons/flow_nodes_editor/nodes/clip_paths.gd` | `PCG/Private/Elements/Polygon/PCGClipPaths.cpp` | default title |
| `Cluster` | - | 缺失 | - | - | `PCG/Public/Elements/PCGClusterElement.h` | default title |
| `Collapse Points` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCollapsePoints.h` | default title |
| `Combine Points` | - | 已有 | `Combine Points` | `demo/addons/flow_nodes_editor/nodes/combine_points.gd` | `PCG/Public/Elements/PCGCombinePoints.h` | default title |
| `Copy Attributes` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCopyAttributes.h` | default title |
| `Copy Points` | - | 已有 | `Copy Points` | `demo/addons/flow_nodes_editor/nodes/copy_points.gd` | `PCG/Public/Elements/PCGCopyPoints.h` | default title |
| `Copy to Render Target` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCopyToRenderTarget.h` | default title |
| `Create Collision Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCreateCollisionData.h` | default title |
| `Create Complex Constant` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGCreateComplexConstantElement.cpp` | default title |
| `Create Constant` | `Create Attribute` | 已有 | `Create Constant` | `demo/addons/flow_nodes_editor/nodes/create_constant.gd` | `PCG/Private/Elements/PCGCreateAttribute.cpp` | manual constant title |
| `Create Points` | - | 已有 | `Grid` | `demo/addons/flow_nodes_editor/nodes/grid.gd` | `PCG/Public/Elements/PCGCreatePoints.h` | default title |
| `Create Points Grid` | - | 已有 | `Grid` | `demo/addons/flow_nodes_editor/nodes/grid.gd` | `PCG/Public/Elements/PCGCreatePointsGrid.h` | default title |
| `Create Points Sphere` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCreatePointsSphere.h` | default title |
| `Create Polygon 2D` | - | 缺失 | - | - | `PCG/Public/Elements/Polygon/PCGCreatePolygon2D.h` | default title |
| `Create Spline` | - | 已有 | `Create Spline` | `demo/addons/flow_nodes_editor/nodes/create_spline.gd` | `PCG/Public/Elements/PCGCreateSpline.h` | default title |
| `Create Surface From Polygon2D` | - | 已有 | `Create Surface From Polygon2D` | `demo/addons/flow_nodes_editor/nodes/create_surface_from_polygon.gd` | `PCG/Public/Elements/Polygon/PCGSurfaceFromPolygon2D.h` | default title |
| `Create Surface From Spline` | - | 已有 | `Create Surface From Spline` | `demo/addons/flow_nodes_editor/nodes/create_surface_from_spline.gd` | `PCG/Public/Elements/PCGCreateSurfaceFromSpline.h` | default title |
| `Create Target Actor` | - | 缺失 | - | - | `PCG/Private/Elements/PCGCreateTargetActor.cpp` | default title |
| `Cull Points Outside Actor Bounds` | - | 缺失 | - | - | `PCG/Private/Elements/PCGCullPointsOutsideActorBounds.cpp` | default title |
| `Custom HLSL` | - | 缺失 | - | - | `PCG/Private/Compute/Elements/PCGCustomHLSL.h` | default title |
| `Data Attributes To Tags` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGDataAttributesAndTags.cpp` | default title |
| `Data Count` | - | 已有 | `Get Data Count` | `demo/addons/flow_nodes_editor/nodes/get_data_count.gd` | `PCG/Private/Elements/PCGDataNum.cpp` | default title |
| `Data Table Row To Attribute Set` | - | 已有 | `Data Table Row To Attribute Set` | `demo/addons/flow_nodes_editor/nodes/data_table_row_to_attribute_set.gd` | `PCG/Public/Elements/PCGDataTableRowToParamData.h` | default title |
| `Data Tags To Attribute Set` | - | 缺失 | - | - | `PCG/Public/Elements/PCGConvertToAttributeSet.h` | default title |
| `Data View To String` | - | 缺失 | - | - | `PCG/Public/Elements/IO/PCGDataViewToStringElement.h` | default title |
| `Debug` | - | 已有 | `Debug` | `demo/addons/flow_nodes_editor/nodes/debug.gd` | `PCG/Public/Elements/PCGDebugElement.h` | default title |
| `Delete Attributes` | - | 已有 | `Remove Attributes` | `demo/addons/flow_nodes_editor/nodes/remove_attribute.gd` | `PCG/Private/Elements/PCGDeleteAttributesElement.cpp` | default title |
| `Delete Tags` | - | 已有 | `Delete Tags` | `demo/addons/flow_nodes_editor/nodes/delete_tags.gd` | `PCG/Private/Elements/PCGDeleteTags.cpp` | default title |
| `Density Filter` | - | 已有 | `Density Filter` | `demo/addons/flow_nodes_editor/nodes/density_filter.gd` | `PCG/Public/Elements/PCGDensityFilter.h` | default title |
| `Density Noise` | - | 已有 | `Attribute Noise` | `demo/addons/flow_nodes_editor/nodes/attribute_noise.gd` | `PCG/Private/Elements/PCGAttributeNoise.cpp` | preconfigured title |
| `Density Remap` | - | 已有 | `Density Remap` | `demo/addons/flow_nodes_editor/nodes/density_remap.gd` | `PCG/Private/Elements/PCGAttributeRemap.cpp`<br>`PCG/Public/Elements/PCGDensityRemapElement.h` | default title |
| `Difference` | - | 已有 | `Difference` | `demo/addons/flow_nodes_editor/nodes/difference.gd` | `PCG/Public/Elements/PCGDifferenceElement.h` | default title |
| `Distance` | - | 已有 | `Distance` | `demo/addons/flow_nodes_editor/nodes/distance.gd` | `PCG/Public/Elements/PCGDistance.h` | default title |
| `Download From GPU` | - | 缺失 | - | - | `PCG/Public/Elements/PCGDownloadFromGPU.h` | default title |
| `Downsample Texture` | - | 缺失 | - | - | `PCG/Private/Elements/PCGDownsampleTexture.cpp` | default title |
| `Duplicate Cross-Sections` | - | 缺失 | - | - | `PCG/Private/Elements/Grammar/PCGDuplicateCrossSections.cpp` | default title |
| `Duplicate Point` | - | 已有 | `Duplicate Point` | `demo/addons/flow_nodes_editor/nodes/duplicate_point.gd` | `PCG/Public/Elements/PCGDuplicatePoint.h` | default title |
| `Edit Points` | - | 缺失 | - | - | `PCG/Public/Elements/PCGEditPoints.h` | default title |
| `Elevation Isolines` | - | 缺失 | - | - | `PCG/Private/Elements/PCGElevationIsolines.cpp` | default title |
| `Execute Blueprint` | - | 缺失 | - | - | `PCG/Public/Elements/PCGExecuteBlueprint.h` | default title |
| `Export Selected Attributes` | - | 缺失 | - | - | `PCG/Public/Elements/IO/PCGExportSelectedAttributes.h` | default title |
| `Extents Modifier` | - | 缺失 | - | - | `PCG/Public/Elements/PCGPointExtentsModifier.h` | default title |
| `Extract Attribute at Index` | - | 已有 | `Get Attribute From Point Index` | `demo/addons/flow_nodes_editor/nodes/get_attribute_from_point_index.gd` | `PCG/Private/Elements/Metadata/PCGExtractAttribute.cpp` | default title |
| `Extract Member From Struct` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGExtractMemberFromStruct.cpp` | default title |
| `Filter Attribute Elements` | - | 已有 | `Filter` | `demo/addons/flow_nodes_editor/nodes/filter.gd` | `PCG/Public/Elements/PCGAttributeFilter.h` | default title |
| `Filter Attribute Elements by Range` | - | 缺失 | - | - | `PCG/Public/Elements/PCGAttributeFilter.h` | default title |
| `Filter Attributes By Name` | - | 缺失 | - | - | `PCG/Private/Elements/PCGDeleteAttributesElement.cpp` | default title |
| `Filter Data - {0}` | - | 缺失 | - | - | `PCG/Private/Elements/PCGFilterByType.cpp` | default title |
| `Filter Data By Attribute` | - | 已有 | `Filter Data By Attribute` | `demo/addons/flow_nodes_editor/nodes/filter_data_by_attribute.gd` | `PCG/Private/Elements/PCGFilterByAttribute.cpp` | default title |
| `Filter Data By Index` | - | 已有 | `Sequence Sample` | `demo/addons/flow_nodes_editor/nodes/sequence_sample.gd` | `PCG/Private/Elements/PCGFilterByIndex.cpp` | default title |
| `Filter Data By Tag` | - | 已有 | `Filter Data By Tag` | `demo/addons/flow_nodes_editor/nodes/filter_data_by_tag.gd` | `PCG/Private/Elements/PCGFilterByTag.cpp` | default title |
| `Filter Data By Type` | - | 已有 | `Filter Data By Type` | `demo/addons/flow_nodes_editor/nodes/filter_data_by_type.gd` | `PCG/Private/Elements/PCGFilterByType.cpp` | default title |
| `Filter Elements By Index` | - | 缺失 | - | - | `PCG/Public/Elements/PCGFilterElementsByIndex.h` | default title |
| `Find Convex Hull 2D` | - | 缺失 | - | - | `PCG/Public/Elements/PCGConvexHull2D.h` | default title |
| `Gather` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGather.h` | default title |
| `Generate Grass Maps` | - | 缺失 | - | - | `PCG/Private/Elements/PCGGenerateLandscapeTextures.cpp` | preconfigured title |
| `Generate Landscape Textures` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGenerateLandscapeTextures.h` | default title |
| `Generate Seed` | `Seed From Value` | 缺失 | - | - | `PCG/Public/Elements/PCGGenerateSeedElement.h` | default title |
| `Get Actor Data` | - | 已有 | `Points From Scene`<br>`Scan Nodes` | `demo/addons/flow_nodes_editor/nodes/points_from_scene.gd`<br>`demo/addons/flow_nodes_editor/nodes/scan_nodes.gd` | `PCG/Public/Elements/PCGDataFromActor.h` | default title |
| `Get Actor Data Layers` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetActorDataLayers.h` | default title |
| `Get Actor Property` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetActorProperty.h` | default title |
| `Get Asset List` | - | 缺失 | - | - | `PCG/Public/Elements/IO/PCGGetAssetList.h` | default title |
| `Get Attribute From Point Index` | - | 已有 | `Get Attribute From Point Index` | `demo/addons/flow_nodes_editor/nodes/get_attribute_from_point_index.gd` | `PCG/Private/Elements/PCGAttributeGetFromPointIndexElement.cpp` | default title |
| `Get Attribute List` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetDataInfo.h` | default title |
| `Get Attribute Set from Index` | - | 缺失 | - | - | `PCG/Private/Elements/PCGAttributeGetFromIndexElement.cpp` | default title |
| `Get Bounds` | - | 已有 | `Make Bounds` | `demo/addons/flow_nodes_editor/nodes/make_bounds.gd` | `PCG/Private/Elements/PCGGetBounds.cpp` | default title |
| `Get Class From Attribute` | - | 缺失 | - | - | `PCG/Private/Elements/PCGGetClassFromAttribute.cpp` | default title |
| `Get Console Variable` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetConsoleVariable.h` | default title |
| `Get Editor Cameras` | - | 缺失 | - | - | `PCG/Private/Elements/Editor/PCGGetEditorCameras.cpp` | default title |
| `Get Editor Selection` | - | 缺失 | - | - | `PCG/Internal/Elements/Editor/PCGGetEditorSelection.h` | default title |
| `Get Element Count` | `Get Points Count` | 已有 | `Get Element Count` | `demo/addons/flow_nodes_editor/nodes/get_points_count.gd` | `PCG/Public/Elements/PCGNumberOfElements.h` | default title |
| `Get Execution Context Info` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetExecutionContext.h` | default title |
| `Get Graph Parameter` | - | 缺失 | - | - | `PCG/Public/Elements/PCGUserParameterGet.h` | default title |
| `Get Landscape Data` | - | 已有 | `Scan Meshes` | `demo/addons/flow_nodes_editor/nodes/scan_meshes.gd` | `PCG/Public/Elements/PCGTypedGetter.h` | default title |
| `Get Loop Index` | - | 已有 | `Get Loop Index` | `demo/addons/flow_nodes_editor/nodes/get_loop_index.gd` | `PCG/Public/Elements/PCGGetLoopIndex.h` | default title |
| `Get PCG Component Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGTypedGetter.h` | default title |
| `Get Primitive Data` | - | 已有 | `Scan Meshes` | `demo/addons/flow_nodes_editor/nodes/scan_meshes.gd` | `PCG/Public/Elements/PCGTypedGetter.h` | default title |
| `Get Property From Object Path` | - | 缺失 | - | - | `PCG/Private/Elements/PCGGetPropertyFromObjectPath.cpp` | default title |
| `Get Resource Path` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetResourcePath.h` | default title |
| `Get Segment` | - | 缺失 | - | - | `PCG/Public/Elements/Polygon/PCGGetSegment.h` | default title |
| `Get Spline Control Points` | - | 缺失 | - | - | `PCG/Private/Elements/PCGGetSplineControlPoints.cpp` | default title |
| `Get Spline Data` | - | 已有 | `Scan Splines` | `demo/addons/flow_nodes_editor/nodes/scan_splines.gd` | `PCG/Public/Elements/PCGTypedGetter.h` | default title |
| `Get Static Mesh Resource Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetStaticMeshResourceData.h` | default title |
| `Get Subgraph Depth` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetSubgraphDepth.h` | default title |
| `Get Tags` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetDataInfo.h` | default title |
| `Get Texture 2D Array Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGGetTexture2DArrayData.h` | default title |
| `Get Texture Data` | - | 已有 | `Texture Sampler` | `demo/addons/flow_nodes_editor/nodes/texture_sampler.gd` | `PCG/Public/Elements/PCGTextureSampler.h` | default title |
| `Get Texture Info` | - | 缺失 | - | - | `PCG/Private/Elements/PCGGetTextureInfo.cpp` | default title |
| `Get Tool Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGDataFromTool.h` | default title |
| `Get Virtual Texture Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGTypedGetter.h` | default title |
| `Get Volume Data` | - | 缺失 | - | - | `PCG/Public/Elements/PCGTypedGetter.h` | default title |
| `Hash Attribute` | - | 缺失 | - | - | `PCG/Public/Elements/Metadata/PCGHashAttribute.h` | default title |
| `Inner Intersection` | - | 缺失 | - | - | `PCG/Public/Elements/PCGInnerIntersectionElement.h` | default title |
| `Input` | - | 已有 | `Input Node` | `demo/addons/flow_nodes_editor/nodes/input.gd` | `PCG/Public/PCGGraph.h` | manual graph node |
| `Instanced Skinned Mesh Spawner` | - | 缺失 | - | - | `PCG/Private/Elements/PCGSkinnedMeshSpawner.cpp` | default title |
| `Intersection` | - | 已有 | `Intersection` | `demo/addons/flow_nodes_editor/nodes/intersection.gd` | `PCG/Public/Elements/PCGOuterIntersectionElement.h` | default title |
| `Load Data Table` | - | 已有 | `Load Data Table` | `demo/addons/flow_nodes_editor/nodes/load_data_table.gd` | `PCG/Private/Elements/IO/PCGDataTableElement.cpp` | default title |
| `Load PCG Data Asset` | - | 已有 | `Load PCG Data Asset` | `demo/addons/flow_nodes_editor/nodes/load_pcg_data_asset.gd` | `PCG/Public/Elements/IO/PCGLoadAssetElement.h` | default title |
| `Loop` | - | 已有 | `Loop` | `demo/addons/flow_nodes_editor/nodes/loop.gd` | `PCG/Private/Elements/PCGLoopElement.cpp` | default title |
| `Make Concrete` | - | 缺失 | - | - | `PCG/Private/Elements/PCGMakeConcreteElement.cpp` | default title |
| `Make Rotator Attribute` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataMakeRotator.cpp` | default title |
| `Make Transform Attribute` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataMakeTransform.cpp` | default title |
| `Make Vector Attribute` | - | 已有 | `Make Vector Attribute` | `demo/addons/flow_nodes_editor/nodes/compose_vector.gd` | `PCG/Private/Elements/Metadata/PCGMetadataMakeVector.cpp` | default title |
| `Match And Set Attributes` | - | 已有 | `Match And Set Attributes` | `demo/addons/flow_nodes_editor/nodes/match_and_set.gd` | `PCG/Private/Elements/PCGMatchAndSetAttributes.cpp` | default title |
| `Max Shader Feature Level Switch` | - | 缺失 | - | - | `PCG/Public/Elements/ControlFlow/PCGShaderFeatureLevelSwitch.h` | default title |
| `Merge Attributes` | - | 缺失 | - | - | `PCG/Private/Elements/PCGMergeAttributes.cpp` | default title |
| `Merge Points` | - | 已有 | `Merge`<br>`Merge Points` | `demo/addons/flow_nodes_editor/nodes/merge.gd`<br>`demo/addons/flow_nodes_editor/nodes/merge_points.gd` | `PCG/Public/Elements/PCGMergeElement.h` | default title |
| `Metadata Array Operation` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGMetadataArrayOperation.cpp` | default title |
| `Mutate Seed` | - | 已有 | `Mutate Seed` | `demo/addons/flow_nodes_editor/nodes/mutate_seed.gd` | `PCG/Public/Elements/PCGMutateSeed.h` | default title |
| `Normal To Density` | - | 已有 | `Normal To Density` | `demo/addons/flow_nodes_editor/nodes/normal_to_density.gd` | `PCG/Public/Elements/PCGNormalToDensity.h` | default title |
| `Offset Polygon` | - | 缺失 | - | - | `PCG/Public/Elements/Polygon/PCGOffsetPolygon2D.h` | default title |
| `Offset Spline` | - | 缺失 | - | - | `PCG/Public/Elements/Spline/PCGOffsetSpline.h` | default title |
| `Output` | - | 已有 | `Output Node` | `demo/addons/flow_nodes_editor/nodes/output.gd` | `PCG/Public/PCGGraph.h` | manual graph node |
| `Parse String` | - | 缺失 | - | - | `PCG/Private/Elements/PCGParseString.cpp` | default title |
| `Partition by Actor Data Layers` | - | 缺失 | - | - | `PCG/Public/Elements/PCGPartitionByActorDataLayers.h` | default title |
| `Pathfinding` | - | 缺失 | - | - | `PCG/Public/Elements/PCGPathfindingElement.h` | default title |
| `Platform Switch` | - | 缺失 | - | - | `PCG/Public/Elements/ControlFlow/PCGPlatformSwitch.h` | default title |
| `Point Filter` | - | 已有 | `Point Filter Range` | `demo/addons/flow_nodes_editor/nodes/point_filter_range.gd` | `PCG/Private/Elements/PCGAttributeFilter.cpp` | preconfigured title |
| `Point Filter Range` | - | 已有 | `Point Filter Range` | `demo/addons/flow_nodes_editor/nodes/point_filter_range.gd` | `PCG/Private/Elements/PCGAttributeFilter.cpp` | preconfigured title |
| `Point From Mesh` | - | 已有 | `Point From Mesh` | `demo/addons/flow_nodes_editor/nodes/point_from_mesh.gd` | `PCG/Private/Elements/PCGPointFromMeshElement.cpp` | default title |
| `Point Match And Set` | - | 缺失 | - | - | `PCG/Public/Elements/PCGPointMatchAndSet.h` | default title |
| `Point Neighborhood` | - | 已有 | `Point Neighborhood` | `demo/addons/flow_nodes_editor/nodes/point_neighborhood.gd` | `PCG/Public/Elements/PCGPointNeighborhood.h` | default title |
| `Point To Attribute Set` | - | 已有 | `Point To Attribute Set` | `demo/addons/flow_nodes_editor/nodes/point_to_attribute_set.gd` | `PCG/Public/Elements/PCGConvertToAttributeSet.h` | default title |
| `Polygon Operation` | - | 已有 | `Polygon Operation` | `demo/addons/flow_nodes_editor/nodes/polygon_operation.gd` | `PCG/Private/Elements/Polygon/PCGPolygon2DOperation.cpp` | default title |
| `Print Grammar` | - | 缺失 | - | - | `PCG/Public/Elements/Grammar/PCGPrintGrammar.h` | default title |
| `Print String` | - | 已有 | `Print String` | `demo/addons/flow_nodes_editor/nodes/print_string.gd` | `PCG/Public/Elements/PCGPrintElement.h` | default title |
| `Projection` | - | 已有 | `Projection` | `demo/addons/flow_nodes_editor/nodes/projection.gd` | `PCG/Public/Elements/PCGProjectionElement.h` | default title |
| `Proxy` | - | 缺失 | - | - | `PCG/Private/Elements/PCGIndirectionElement.cpp` | default title |
| `Random Choice` | - | 缺失 | - | - | `PCG/Private/Elements/PCGRandomChoice.cpp` | default title |
| `Remove Actors From World` | - | 缺失 | - | - | `PCG/Private/Elements/Editor/PCGRemoveActorsFromWorld.cpp` | default title |
| `Remove Empty Data` | - | 缺失 | - | - | `PCG/Private/Elements/PCGRemoveEmptyData.cpp` | default title |
| `Replace Data By Tag` | - | 缺失 | - | - | `PCG/Public/Elements/Data/PCGReplaceDataByTags.h` | default title |
| `Replace Tags` | - | 已有 | `Replace Tags` | `demo/addons/flow_nodes_editor/nodes/replace_tags.gd` | `PCG/Private/Elements/PCGReplaceTags.cpp` | default title |
| `Reroute` | - | 已有 | `` | `demo/addons/flow_nodes_editor/nodes/reroute.gd` | `PCG/Public/Elements/PCGReroute.h`<br>`PCGEditor/Private/Nodes/PCGEditorGraphNodeReroute.cpp` | manual graph node |
| `Reset Point Center` | - | 缺失 | - | - | `PCG/Public/Elements/PCGResetPointCenter.h` | default title |
| `Runtime Quality Branch` | - | 缺失 | - | - | `PCG/Public/Elements/ControlFlow/PCGQualityBranch.h` | default title |
| `Runtime Quality Select` | - | 缺失 | - | - | `PCG/Public/Elements/ControlFlow/PCGQualitySelect.h` | default title |
| `Sample Texture` | - | 缺失 | - | - | `PCG/Public/Elements/PCGSampleTexture.h` | default title |
| `Sanity Check Point Data` | - | 已有 | `Sanity Check Point Data` | `demo/addons/flow_nodes_editor/nodes/sanity_check.gd` | `PCG/Public/Elements/PCGSanityCheckPointData.h` | default title |
| `Save Data View` | - | 缺失 | - | - | `PCG/Public/Elements/IO/PCGSaveDataViewElement.h` | default title |
| `Save PCG Data Asset` | - | 缺失 | - | - | `PCG/Public/Elements/IO/PCGSaveAssetElement.h` | default title |
| `Save Texture to Asset` | - | 缺失 | - | - | `PCG/Public/Elements/PCGSaveTextureToAsset.h` | default title |
| `Scene Capture` | - | 缺失 | - | - | `PCG/Public/Elements/PCGSceneCapture.h` | default title |
| `Select` | - | 已有 | `Select` | `demo/addons/flow_nodes_editor/nodes/select.gd` | `PCG/Private/Elements/ControlFlow/PCGBooleanSelect.cpp` | default title |
| `Select (Multi)` | `Select (Integer)` | 已有 | `Select (Multi)` | `demo/addons/flow_nodes_editor/nodes/select_multi.gd` | `PCG/Private/Elements/ControlFlow/PCGMultiSelect.cpp` | manual constant title |
| `Select Grammar` | - | 缺失 | - | - | `PCG/Private/Elements/Grammar/PCGSelectGrammar.cpp` | default title |
| `Select Points` | - | 已有 | `Select Points` | `demo/addons/flow_nodes_editor/nodes/select_points.gd` | `PCG/Public/Elements/PCGSelectPoints.h` | default title |
| `Self Pruning` | - | 已有 | `Self Pruning` | `demo/addons/flow_nodes_editor/nodes/self_pruning.gd` | `PCG/Public/Elements/PCGSelfPruning.h` | default title |
| `Set Grid Size` | - | 缺失 | - | - | `PCG/Private/Elements/PCGHiGenGridSize.cpp` | default title |
| `Sort Attributes` | `Sort Points` | 已有 | `Sort Attributes` | `demo/addons/flow_nodes_editor/nodes/sort.gd` | `PCG/Private/Elements/PCGSortAttributes.cpp` | default title |
| `Sort Data By Tag Value` | - | 缺失 | - | - | `PCG/Private/Elements/PCGSortTags.cpp` | default title |
| `Spatial Noise` | - | 已有 | `Spatial Noise` | `demo/addons/flow_nodes_editor/nodes/noise.gd` | `PCG/Public/Elements/PCGSpatialNoise.h` | default title |
| `Spawn Actor` | - | 已有 | `Spawn Scenes` | `demo/addons/flow_nodes_editor/nodes/spawn_scenes.gd` | `PCG/Public/Elements/PCGSpawnActor.h` | default title |
| `Spawn Spline Component` | - | 缺失 | - | - | `PCG/Private/Elements/PCGSpawnSpline.cpp` | default title |
| `Spawn Spline Mesh` | - | 缺失 | - | - | `PCG/Public/Elements/PCGSpawnSplineMesh.h` | default title |
| `Spline Direction` | - | 缺失 | - | - | `PCG/Private/Elements/PCGSplineDirection.cpp` | default title |
| `Spline Intersection` | - | 缺失 | - | - | `PCG/Private/Elements/PCGSplineIntersection.cpp` | default title |
| `Spline Sampler` | - | 已有 | `Sample Spline` | `demo/addons/flow_nodes_editor/nodes/sample_spline.gd` | `PCG/Public/Elements/PCGSplineSampler.h` | default title |
| `Spline to Segment` | - | 已有 | `Spline to Segment` | `demo/addons/flow_nodes_editor/nodes/spline_to_segment.gd` | `PCG/Private/Elements/Grammar/PCGSplineToSegment.cpp` | default title |
| `Split Points` | - | 缺失 | - | - | `PCG/Public/Elements/PCGSplitPoints.h` | default title |
| `Split Spline` | - | 缺失 | - | - | `PCG/Private/Elements/PCGSplitSplines.cpp` | default title |
| `Static Mesh Spawner` | - | 已有 | `Spawn Meshes` | `demo/addons/flow_nodes_editor/nodes/spawn_meshes.gd` | `PCG/Private/Elements/PCGStaticMeshSpawner.cpp` | default title |
| `Subdivide Segment` | - | 缺失 | - | - | `PCG/Private/Elements/Grammar/PCGSubdivideSegment.cpp` | default title |
| `Subdivide Spline` | - | 缺失 | - | - | `PCG/Public/Elements/Grammar/PCGSubdivideSpline.h` | default title |
| `Subgraph` | - | 已有 | `Subgraph` | `demo/addons/flow_nodes_editor/nodes/subgraph.gd` | `PCG/Public/PCGSubgraph.h` | manual graph node |
| `Surface Sampler` | - | 已有 | `Surface Sampler` | `demo/addons/flow_nodes_editor/nodes/surface_sampler.gd` | `PCG/Public/Elements/PCGSurfaceSampler.h` | default title |
| `Switch` | - | 已有 | `Switch` | `demo/addons/flow_nodes_editor/nodes/switch.gd` | `PCG/Private/Elements/ControlFlow/PCGSwitch.cpp` | manual constant title |
| `Tags to Data Attributes` | - | 缺失 | - | - | `PCG/Private/Elements/Metadata/PCGDataAttributesAndTags.cpp` | default title |
| `Teleport Actors And Components` | - | 缺失 | - | - | `PCG/Internal/Elements/Editor/PCGTeleportElement.h` | default title |
| `To Data View` | - | 缺失 | - | - | `PCG/Public/Elements/PCGConvertToDataView.h` | default title |
| `To Point` | - | 缺失 | - | - | `PCG/Public/Elements/PCGCollapseElement.h` | default title |
| `Transform Points` | - | 已有 | `Transform Points` | `demo/addons/flow_nodes_editor/nodes/transform_points.gd` | `PCG/Public/Elements/PCGTransformPoints.h` | default title |
| `Union` | - | 已有 | `Union` | `demo/addons/flow_nodes_editor/nodes/union.gd` | `PCG/Public/Elements/PCGUnionElement.h` | default title |
| `Visualize Attribute` | - | 缺失 | - | - | `PCG/Public/Elements/PCGVisualizeAttribute.h` | default title |
| `Volume Sampler` | - | 已有 | `Volume Sampler` | `demo/addons/flow_nodes_editor/nodes/volume_sampler.gd` | `PCG/Public/Elements/PCGVolumeSampler.h` | default title |
| `Wait` | - | 缺失 | - | - | `PCG/Public/Elements/ControlFlow/PCGWait.h` | default title |
| `Wait Until Landscape Is Ready` | - | 缺失 | - | - | `PCG/Public/Elements/Landscape/PCGWaitLandscapeReady.h` | default title |
| `World Ray Hit Query` | - | 已有 | `Ray Cast` | `demo/addons/flow_nodes_editor/nodes/ray_cast.gd` | `PCG/Public/Elements/PCGWorldQuery.h` | default title |
| `World Raycast` | `World Sweep`<br>`World Trace` | 缺失 | - | - | `PCG/Private/Elements/PCGWorldRaycast.cpp` | default title |
| `World Volumetric Query` | - | 已有 | `Physics Overlap Query` | `demo/addons/flow_nodes_editor/nodes/physics_overlap_query.gd` | `PCG/Public/Elements/PCGWorldQuery.h` | default title |
| `Write Data Index` | - | 缺失 | - | - | `PCG/Public/Elements/PCGWriteDataIndex.h` | default title |

## Flow Nodes Without Direct UE PCG Title Match

These are Flow nodes whose title and aliases did not match any extracted UE PCG node title or UE title alias. Some are Godot integration nodes, convenience nodes, narrower partial nodes, or project-specific legacy nodes. Fuzzy title matches were not accepted unless the source-level input/output and function were close.

| Flow node | Category | File | Aliases |
|---|---|---|---|
| `Assets` | Input | `demo/addons/flow_nodes_editor/nodes/assets.gd` | `Asset List`, `Weighted Assets`, `Mesh Entries` |
| `Attribute Random` | Metadata | `demo/addons/flow_nodes_editor/nodes/attribute_random.gd` | `Random Attribute` |
| `Build Rotation From Up Vector` | Spatial | `demo/addons/flow_nodes_editor/nodes/build_rotation_from_up.gd` | `Build Rotation From Up Vector`, `Make Rot` |
| `Clip Points By Polygon` | Spatial | `demo/addons/flow_nodes_editor/nodes/clip_points_by_polygon.gd` | - |
| `Copy` | Spatial | `demo/addons/flow_nodes_editor/nodes/copy.gd` | - |
| `Curve Remap Density` | Density | `demo/addons/flow_nodes_editor/nodes/curve_remap_density.gd` | `Curve Remap Density` |
| `Distance to Density` | - | `demo/addons/flow_nodes_editor/nodes/distance_to_density.gd` | - |
| `Dungeon Connect Rooms` | Spatial | `demo/addons/flow_nodes_editor/nodes/dungeon_connect_rooms.gd` | `corridors`, `connect rooms`, `L corridor` |
| `Dungeon Expand Rooms` | Spatial | `demo/addons/flow_nodes_editor/nodes/dungeon_expand_rooms.gd` | `expand rooms`, `room tiles`, `floor tiles` |
| `Dungeon Generator` | Sampler | `demo/addons/flow_nodes_editor/nodes/dungeon_generator.gd` | `dungeon`, `rooms and corridors`, `level generator` |
| `Dungeon Room Candidates` | Sampler | `demo/addons/flow_nodes_editor/nodes/dungeon_room_candidates.gd` | `room candidates`, `random rooms` |
| `Dungeon Walls and Doors` | Spatial | `demo/addons/flow_nodes_editor/nodes/dungeon_walls_and_doors.gd` | `dungeon walls`, `dungeon doors`, `wall builder` |
| `Expression` | Metadata | `demo/addons/flow_nodes_editor/nodes/expression.gd` | `Attribute Expression` |
| `Get Entries Count` | Utility | `demo/addons/flow_nodes_editor/nodes/get_entries_count.gd` | `Entries Count` |
| `Get Variable` | Metadata | `demo/addons/flow_nodes_editor/nodes/get_variable.gd` | `variable`, `get` |
| `Grid Boundary` | Spatial | `demo/addons/flow_nodes_editor/nodes/grid_boundary.gd` | `boundary`, `walls from cells`, `grid edges` |
| `Grid Connect Points` | Spatial | `demo/addons/flow_nodes_editor/nodes/grid_connect_points.gd` | `connect points`, `grid path`, `orthogonal path` |
| `Grid Fill Bounds` | Sampler | `demo/addons/flow_nodes_editor/nodes/grid_fill_bounds.gd` | - |
| `Load Alembic File` | Input | `demo/addons/flow_nodes_editor/nodes/load_alembic_file.gd` | `Load Alembic File` |
| `Make Vector` | Utility | `demo/addons/flow_nodes_editor/nodes/make_vector.gd` | `Vector Constant`, `Make Vec3` |
| `Mesh Sampler` | Sampler | `demo/addons/flow_nodes_editor/nodes/mesh_sampler.gd` | `Mesh Sampler` |
| `Navigation Region Sampler` | Sampler | `demo/addons/flow_nodes_editor/nodes/navigation_region_sampler.gd` | `Navmesh Sampler` |
| `Physics Shape Sweep` | Spatial | `demo/addons/flow_nodes_editor/nodes/physics_shape_sweep.gd` | `Shape Sweep`, `Shape Trace` |
| `Point From Player` | Sampler | `demo/addons/flow_nodes_editor/nodes/point_from_player_pawn.gd` | `Point From Player Pawn`, `sample player`, `player character`, `player pawn`, `source point`, `scene source` |
| `Point Offsets` | Spatial | `demo/addons/flow_nodes_editor/nodes/point_offsets.gd` | `children`, `sockets`, `local offsets`, `scatter children` |
| `Points From GridMap` | Sampler | `demo/addons/flow_nodes_editor/nodes/points_from_gridmap.gd` | - |
| `Points From Imported Scene` | Sampler | `demo/addons/flow_nodes_editor/nodes/points_from_imported_scene.gd` | - |
| `Points From TileMap` | Sampler | `demo/addons/flow_nodes_editor/nodes/points_from_tilemap.gd` | - |
| `Random Color` | Metadata | `demo/addons/flow_nodes_editor/nodes/random_color.gd` | - |
| `Relax` | Spatial | `demo/addons/flow_nodes_editor/nodes/relax.gd` | `Relax Points` |
| `Sample Mesh` | Sampler | `demo/addons/flow_nodes_editor/nodes/sample_mesh.gd` | `Mesh Sampler` |
| `Sample Points` | Sampler | `demo/addons/flow_nodes_editor/nodes/sample_points.gd` | `Point Subdivision`, `Blue Noise`, `Quasi Random Points` |
| `Set Variable` | Metadata | `demo/addons/flow_nodes_editor/nodes/set_variable.gd` | `variable`, `set` |
| `Size` | Utility | `demo/addons/flow_nodes_editor/nodes/size.gd` | `Count`, `Num Points` |
| `Snap to Grid` | Spatial | `demo/addons/flow_nodes_editor/nodes/snap_to_grid.gd` | `Snap To Grid`, `Quantize Transform` |
| `Spawn Nodes` | Spawner | `demo/addons/flow_nodes_editor/nodes/spawn_nodes.gd` | `Spawn Actor (Nodes)` |
| `Substract` | - | `demo/addons/flow_nodes_editor/nodes/substract.gd` | - |
| `Tags` | - | `demo/addons/flow_nodes_editor/nodes/tags_mutate.gd` | - |
| `Transform` | - | `demo/addons/flow_nodes_editor/nodes/transform.gd` | - |

## Notes

- `preconfigured title` rows are UE settings variants exposed as separate menu/search entries, such as Density Remap or Attribute Filter Range.
- `manual graph node` and `manual constant title` rows are UE nodes whose titles are returned through graph/editor infrastructure or source constants not captured by the simple automatic extractor.
- Exact behavior parity still needs focused tests per node, especially for rows matched through aliases rather than identical titles.
