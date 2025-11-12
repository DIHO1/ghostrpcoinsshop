fx_version 'cerulean'
game 'gta5'

lua54 'yes'

shared_script 'config.lua'

client_script 'client.lua'
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/images/props/*.svg'
}
