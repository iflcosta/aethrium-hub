function onUpdateDatabase()
	print("> Updating database to version 40 (Fix Super UP duplicates)")
	
	-- Limpar dados duplicados e manter apenas um registro por hunt_id
	db.query("DELETE FROM exclusive_hunts")
	db.query("INSERT INTO exclusive_hunts (`hunt_id`, `guid_player`, `time`, `to_time`) VALUES 
		(20000, '0', 0, 0), 
		(20001, '0', 0, 0),
		(20002, '0', 0, 0),
		(20003, '0', 0, 0),
		(20004, '0', 0, 0),
		(20005, '0', 0, 0),
		(20006, '0', 0, 0),
		(20007, '0', 0, 0),
		(20008, '0', 0, 0),
		(20009, '0', 0, 0),
		(20010, '0', 0, 0),
		(20011, '0', 0, 0),
		(20012, '0', 0, 0),
		(20013, '0', 0, 0),
		(20014, '0', 0, 0),
		(20015, '0', 0, 0),
		(20016, '0', 0, 0),
		(20017, '0', 0, 0),
		(20018, '0', 0, 0),
		(20019, '0', 0, 0),
		(20020, '0', 0, 0)")
	
	return true
end
