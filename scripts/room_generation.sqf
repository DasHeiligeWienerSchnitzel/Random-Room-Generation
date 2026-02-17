params ["_room_1","_room_2","_room_3","_room_4","_room_5","_room_6","_room_7","_room_8","_room_9","_room_10"];

_rooms = [_room_1,_room_2,_room_3,_room_4,_room_5,_room_6,_room_7,_room_8,_room_9,_room_10];
_amount = 16;
_startPosition = getPos shoothouse_start;
_startDirection = "south";
_maximumDistanceOld = 0;

//Generates x-amount of rooms.
for "_i" from 0 to _amount do {
	hint format ["Loop Amount: %1",_i];
	_directions = ["north","east","south","west"];
	_entrancePossible = false;
	_collision = true;
	_randomRoom = [];
	_relPosToCenter = [0,0];
	
	//Repeats random room selection till a possible room-connection has been found.
	while {_entrancePossible == false or _collision == true} do {
		_distances = [];
		_randomRoom = selectRandom _rooms;
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
		_centerDistance = _startPosition distance2D _newPosition;
		
		_collision = !(_centerDistance > (_maximumDistanceOld + _maximumDistanceNew + 0.5));
		systemChat format ["%1 > %2",_centerDistance,_maximumDistanceOld + _maximumDistanceNew + 0.5];
	};
	
	//Creates the room.
	_newPosition = _startPosition vectorDiff _relPosToCenter;
	[_newPosition, 0, _randomRoom, 0] call BIS_fnc_objectsMapper;
	
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
	
	sleep 1;
};
