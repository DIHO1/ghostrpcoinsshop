fx_version 'cerulean'
game 'gta5'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/styles.css',
    'html/fonts/**/*.ttf',
    'html/images/**/*.*'
}
