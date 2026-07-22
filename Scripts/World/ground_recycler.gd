extends Node3D

## Recicla las filas de GroundTile01 para simular un piso infinito.
## El jugador avanza hacia Z negativo (velocity.z = -10 en player.gd).
## Cada fila que el jugador ya dejó atrás (Z más grande que el jugador)
## se manda al frente de todo (Z más chico que la fila más adelantada),
## para que el piso nunca se acabe.

@export var player_path: NodePath
@export var row_spacing := 2.5
@export var recycle_margin := 15.0

var rows: Array = [] # Filas ordenadas de más adelante (Z chico) a más atrás (Z grande)
var player: Node3D

func _ready():
	player = get_node_or_null(player_path)
	if player == null:
		push_warning("GroundRecycler: player_path no está asignado o no se encontró el nodo.")
		return
	_group_children_into_rows()

func _group_children_into_rows():
	var by_z := {}
	for child in get_children():
		var z = child.transform.origin.z
		if not by_z.has(z):
			by_z[z] = []
		by_z[z].append(child)

	var zs = by_z.keys()
	zs.sort() # ascendente: de Z más chico (adelante) a Z más grande (atrás)

	rows.clear()
	for z in zs:
		rows.append(by_z[z])

func _process(_delta):
	if rows.is_empty() or player == null:
		return

	# La última fila del array es la que está más atrás (Z más grande).
	var rear_row: Array = rows[rows.size() - 1]
	var rear_z: float = rear_row[0].transform.origin.z

	# Si el jugador ya pasó esa fila (avanzó más allá, hacia -Z) por más de recycle_margin,
	# la reciclamos poniéndola adelante de la fila más adelantada.
	if player.global_position.z < rear_z - recycle_margin:
		var front_row: Array = rows[0]
		var front_z: float = front_row[0].transform.origin.z
		var new_z: float = front_z - row_spacing

		for tile in rear_row:
			var t = tile.transform
			t.origin.z = new_z
			tile.transform = t

		rows.remove_at(rows.size() - 1)
		rows.insert(0, rear_row)
