params ["_room_1","_room_2","_room_3","_room_4","_room_5","_room_6","_room_7","_room_8","_room_9","_room_10"];

_rooms = [_room_1,_room_2,_room_3,_room_4,_room_5,_room_6,_room_7,_room_8,_room_9,_room_10];
_endRooms = [_endRoom_1,_endRoom_2,_endRoom_3,_endRoom_4];

_roomRadius = [];
{
	_max = 0;
	{
		_d = [0,0,0] distance2D (_x select 1);
		if (_d > _max) then {_max = _d};
	}forEach _x;
	_roomRadius pushBack _max;
}forEach _rooms;

_endRoomRadius = [];
{
	_max = 0;
	{
		_d = [0,0,0] distance2D (_x select 1);
		if (_d > _max) then {_max = _d};
	}forEach _x;
	_endRoomRadius pushBack _max;
}forEach _endRooms;

_amount = 100;
_startPosition = getPos shoothouse_start;
_startDirection = "south";
_maximumDistanceOld = 0;
_placedRooms = [];

//Generates x-amount of rooms.
_stopGeneration = false;
_bestCount = 0;
_finalStuckCounter = 0;
_targetRooms = _amount;
_iteration = 0;
while {(count _placedRooms) < _targetRooms && !_stopGeneration} do {
	_directions = ["north","east","south","west"];
	_entrancePossible = false;
	_collision = false;
	_randomRoom = [];
	_relPosToCenter = [0,0];
	_newPosition = [0,0,0];
	_newRadius = 0;
	
	//Repeats random room selection till a possible room-connection has been found.
	_tries = 0;
	
	while {_entrancePossible == false or _collision == true} do {
		hint format ["Rooms: %1/%2\nIterations: %3\nTries:%4\nStuck:%5",count _placedRooms,_targetRooms,_iteration,_tries,_finalStuckCounter];
		_tries = _tries + 1;
		if (_tries >= 50) then {
			_finalStuckCounter = _finalStuckCounter + 1;

			if ((count _placedRooms) == 0) exitWith {
				_entrancePossible = true;
				_collision = false;
			};
			
			_lastRoom = _placedRooms deleteAt ((count _placedRooms) - 1);
			
			{deleteVehicle _x} forEach (_lastRoom select 2);
			
			_startPosition = _lastRoom select 3;
			_startDirection = _lastRoom select 4;
			
			_tries = 0;
			
			_entrancePossible = false;
			
			_collision = true;
			
						if (_finalStuckCounter == 50) then {
				_yaw = switch (_startDirection) do {
					case "north": {180};
					case "south": {0};
					case "east": {270};
					case "west": {90};
				};
				
				_wall = createVehicle ["Land_Shoot_House_Wall_F", _startPosition, [], 0, "CAN_COLLIDE"];
				_wall setDir _yaw;
				_wall setPos _startPosition;
				
				_stopGeneration = true;
				_entrancePossible = true;
				_collision = false;
			};
			
			continue;
		};
		
		_distances = [];
		_placingEndRoom = ((count _placedRooms) == (_targetRooms - 1));
		if (_placingEndRoom) then {
			_randomRoom = selectRandom _endRooms;
		}else{
			_randomRoom = selectRandom _rooms;
		};
		
		_entrancePossible = false;
		_relPosToCenter = [0,0,0];
		
		{
			_name = _x select 6;
			_distances pushBack ([0,0,0] distance2D (_x select 1));
			if (_name != "") then {
				if ((_name splitString "_" select -1) == _startDirection) then {
					_entrancePossible = true;
					_relPosToCenter = _x select 1;
				};
			};
		}forEach _randomRoom;
		if (!_entrancePossible) then {continue};
		
		_maximumDistanceNew = selectMax _distances;
		_newPosition = _startPosition vectorDiff _relPosToCenter;
		if (_placingEndRoom) then {
			_newRadius = _endRoomRadius select (_endRooms find _randomRoom);
		}else{
			_newRadius = _roomRadius select (_rooms find _randomRoom);
		};
		
		_collision = false;
		_countPlaced = count _placedRooms;
		{
			if (_forEachIndex != _countPlaced - 1) then {
				_oldCenter = _x select 0;
				_oldRadius = _x select 1;
				
				if ((_newPosition distance2D _oldCenter) < (_newRadius + _oldRadius + 0.5)) exitWith {
					_collision = true;
				};
				if (false) then {
					systemChat format ["Check vs #%1: d=%2  limit=%3",
						_forEachIndex,
						(_newPosition distance2D _oldCenter),
						(_newRadius + _oldRadius + 0.5)
					];
				};
			};
		}forEach _placedRooms;
	};
	if (_stopGeneration) exitWith {};
	
	//Creates the room.
	_newPosition = _startPosition vectorDiff _relPosToCenter;
	_spawnedObjects = [_newPosition, 0, _randomRoom, 0] call BIS_fnc_objectsMapper;
	_placedRooms pushBack [
		_newPosition,
		_newRadius,
		_spawnedObjects,
		_startPosition,
		_startDirection
	];
	if ((count _placedRooms) > _bestCount) then {
		_bestCount = count _placedRooms;
		_finalStuckCounter = 0;
	};
	
	//Gets possible Entrances and Directions
	_directions deleteAt (_directions find _startDirection);
	_nextEntrances = [];
	_possibleDirections = [];
	{
		_name = _x select 6;
		if (_name != "") then {
			_direction = _name splitString "_" select -1;
			if (_direction in _directions) then {
				_nextEntrances pushBack (_x select 1);
				_possibleDirections pushBack _direction;
			};
		};
	}forEach _randomRoom;
	
	//Sets position and direction of next entrance and spawnpoint of next room.
	if ((count _placedRooms) < _targetRooms) then {
		_nextEntrancePosition = selectRandom _nextEntrances;
		_startPosition = _newPosition vectorAdd _nextEntrancePosition;
		_index = _randomRoom findIf {(_x select 1) isEqualTo _nextEntrancePosition};
		_nextEntranceDirection = _possibleDirections select (_nextEntrances find _nextEntrancePosition);
		switch (_nextEntranceDirection) do
		{
			case "north": {_startDirection = "south"};
			case "east": {_startDirection = "west"};
			case "south": {_startDirection = "north"};
			case "west": {_startDirection = "east"};
		}; 
	};
	_iteration = _iteration + 1;
};
