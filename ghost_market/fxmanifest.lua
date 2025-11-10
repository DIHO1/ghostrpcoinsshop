fx_version 'cerulean'
game 'gta5'
author 'Jules'
description 'Ghost Market - In-game shop system'
version '1.0.0'

shared_script 'config.lua'
server_script 'server.lua'
client_script 'client.lua'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

lua54 'yes'
