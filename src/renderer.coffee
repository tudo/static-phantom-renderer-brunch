system = require 'system'
fs = require 'fs'
_ = require 'underscore'
path = require 'path'

page = require('webpage').create()
address = system.args[1]
dir = system.args[2]
filename = system.args[3]
removeScripts = system.args[4] is "true"

if system.args.length < 3
	console.log 'Usage: render.js <url> <dir> <filename>'
	phantom.exit()

unless fs.isFile 'app/assets/index.html'
	console.error 'no index.html found at \'app/assets\''
	phantom.exit()

index = fs.read 'app/assets/index.html'

page.open address, (status) ->
	if (status isnt 'success')
		console.log('FAIL to load the address', address)
		phantom.exit()
	else
		page.viewportSize = { width: 320, height: 480 }

		if removeScripts
			noOfScriptsRemoved = page.evaluate ->
				noOfScripts = 0
				script = document.getElementsByTagName('script')[0]
				while script
					if script?.parentNode?.removeChild?
						script.parentNode.removeChild script
						noOfScripts++
					script = document.getElementsByTagName('script')[0]
				noOfScripts

		document = page.evaluate () ->
			return document.getElementsByTagName('html')[0].outerHTML

		beginIndex = index.indexOf '<!-- static-renderer BEGIN -->'
		beginDocument = document.indexOf '<!-- static-renderer BEGIN -->'
		endIndex = index.indexOf '<!-- static-renderer END -->'

		pre = ""
		if beginIndex isnt -1
			pre = index.slice 0, beginIndex
		if beginDocument isnt -1
			document = document.slice beginDocument, document.length

		endDocument = document.indexOf '<!-- static-renderer END -->'

		post = ""
		if endIndex isnt -1
			post = index.slice endIndex, index.length
		if endDocument isnt -1
			document = document.slice 0, endDocument

		html = pre + document + post

		console.log 'writing', path.join(dir, filename) + (if removeScripts then " | removed #{noOfScriptsRemoved} scripts" else "")
		fs.write path.join(dir, filename), html, 'w'

		phantom.exit()
