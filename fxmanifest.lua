fx_version 'cerulean'
game 'gta5'

name "grave_motels"
description "A motel Script using ox_doorlock"
author "GraveDigger7863"
version "1.0.0"

shared_scripts {
	'shared/*.lua',
	'@es_extended/imports.lua',
	'@ox_lib/init.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

lua54 'yes'