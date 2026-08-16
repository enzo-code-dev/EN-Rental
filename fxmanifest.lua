--[[
███████╗███╗   ██╗███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝████╗  ██║╚══███╔╝██╔═══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║    ██║     ██║   ██║██║  ██║█████╗
██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║    ██║     ██║   ██║██║  ██║██╔══╝
███████╗██║ ╚████║███████╗╚██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗
╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

               DISCORD • https://discord.gg/HPEAWNB52w
]]

fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'EN-Rental'
author 'ENZO CODE'
version '4.1.1'
description 'ENZO CODE multi-framework vehicle rental for ESX and QBCore'

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/**/*'
}
