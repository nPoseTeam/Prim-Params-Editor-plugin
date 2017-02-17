# nPose Prim Params Editor plugin

## Requirements
nPose V3 and above.

##Usage
The plugin contains 2 scripts `nPose Prim Params Editor plugin, main` (we will call it the `main`script) and `nPose Prim Params Editor plugin, storage` (we will call it the `storage`script).
### `main` Script
The `main` script has to be placed into the linkset you want to manipulate. This can be the nPose main Object and/or a prop or if you want to manipulate both then place it into both.
### `storage` Script
The `storage` script is optional. If you don't work with props, you don't need it. If you work with props, you may want to rez a prop with the same appearance that was selected previously. To achieve this, place the `storage` script into the main object.
### Prim description
to "address" a prim inside a linkset we use the description field of the prim to give it an identifier. Please don't use plain numbers as identifier. If you want to give a prim more than one identifier then separate the identifiers by `~`. You can also use one identifier for more than one prim.
### Command Syntax
```
LINKMSG|-8050|command~identifier~parameter[~parameter...][~command~identifier~parameter[~parameter...]...]
```
### Example
```
LINKMSG|-8050|COLOR~mainObject~-1~<1.0, 0.0, 0.0>
```
This will set the color of all faces of the prim with the description mainObject to red.

####commands
| command            | parameters                        | description |
| ------------------ | --------------------------------- | ----------- |
| `TEXTURE`          | integer face, string uuid or name |
| `COLOR`            | integer face, vector color        |
| `ALPHA`            | integer face, float alpha         |

Additionally all non deprecated "commands" (but one) of the [llSetPrimitiveParams](http://wiki.secondlife.com/wiki/LlSetPrimitiveParams) LSL command are implemented.
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

 
