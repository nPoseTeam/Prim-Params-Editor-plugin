# nPose Prim Params Editor plugin

## Requirements
nPose V3 and above.

## Usage
Add the following line to the top of your `.init` NC (if you don't have an `.init` NC then create one):
```
PLUGINCOMMAND|PRIMEDIT|-8500
```
If you want to use the Prim Params Editor plugin for props add the following lines (instead of the above);
```
PLUGINCOMMAND|PRIMEDIT|-8500
```
The plugin contains 2 scripts `nPose Prim Params Editor plugin, main` (we will call it the `main`script) and `nPose Prim Params Editor plugin, storage` (we will call it the `storage`script).
### `main` Script
The `main` script has to be placed into the linkset you want to manipulate. This can be the nPose main Object and/or a prop or if you want to manipulate both then place it into both.
### `storage` Script
The `storage` script is optional. If you don't work with props, you don't need it. If you work with props, you may want to rez a prop with the same appearance that was selected previously. To achieve this, place the `storage` script into the main object.
### Prim description
To "address" a prim inside a linkset we use the description field of the prim to give it an identifier. Please don't use plain numbers as identifier. If you want to give a prim more than one identifier then separate the identifiers by `~`. You can also use one identifier for more than one prim.
### Command Syntax
```
PRIMEDIT|command~identifier~parameter[~parameter...][~command~identifier~parameter[~parameter...]...]
```
### Example
```
PRIMEDIT|COLOR~mainObject~-1~<1.0, 0.0, 0.0>
```
This will set the color of all faces of the prim with the description mainObject to red.

## commands
| command               | Version | parameters                                                                     | description |
| --------------------- | ------- | ------------------------------------------------------------------------------ | ----------- |
| `TEXTURE`             | 1.00    | integer face, string uuid or name                                              | puts a texture onto the prim |
| `COLOR`               | 1.00    | integer face, vector color                                                     | sets the color of a prim |
| `ALPHA`               | 1.00    | integer face, float alpha                                                      | sets the transparency of a prim |
| `REL_POS_LOCAL`       | 1.00    | vector referenceSize, vector currentSize, vector targetPosition                | moves a prim within the linkset to a postion (relative to the current size of the object) |
| `REL_SIZE`            | 1.00    | vector referenceSize, vector currentSize, vector targetSize                    | scales a prim (relative to the current size of the object) |
| `OFFSET_POSITION`     | 1.01    | vector offset, vector targetPosition                                           | moves a prim to offset+targetPosition |
| `OFFSET_REL_POSITION` | 1.01    | vector offset, vector referenceSize, vector currentSize, vector targetPosition | moves a prim to offset+relativeTargetPosition |
| `PRIM_`...            | 1.00    | see below                                                                      | see below |

All non deprecated "commands" (but one) of the [llSetPrimitiveParams](http://wiki.secondlife.com/wiki/LlSetPrimitiveParams) LSL command are implemented.
```
PRIM_MATERIAL
PRIM_PHYSICS
PRIM_TEMP_ON_REZ
PRIM_PHANTOM
PRIM_POSITION
PRIM_SIZE
PRIM_ROTATION
PRIM_TEXTURE
PRIM_COLOR
PRIM_BUMP_SHINY
PRIM_FULLBRIGHT
PRIM_FLEXIBLE
PRIM_TEXGEN
PRIM_POINT_LIGHT
PRIM_GLOW
PRIM_TEXT
PRIM_DESC
PRIM_ROT_LOCAL
PRIM_PHYSICS_SHAPE_TYPE
PRIM_OMEGA
PRIM_POS_LOCAL
PRIM_LINK_TARGET
PRIM_SLICE
PRIM_SPECULAR
PRIM_NORMAL
PRIM_ALPHA_MODE
PRIM_ALLOW_UNSIT
PRIM_SCRIPTED_SIT_ONLY
PRIM_SIT_TARGET
```

 
