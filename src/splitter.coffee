buffers = require "buffers"
Stream = require "stream"

module.exports = splitter = (delim) ->
	stream = new Stream()
	buf = buffers()

	delim = new Buffer delim unless Buffer.isBuffer delim
	delimLen = delim.length

	stream.writable = true
	src = null

	emitToken = (token) ->
		token = token.toString stream.encoding if stream.encoding
		stream.emit "token", token

	doSplit = ->
		finalIndex = -1
		while (index = buf.indexOf(delim, Math.max(finalIndex, 0))) > -1
			emitToken buf.slice Math.max(finalIndex, 0), index
			finalIndex = index + delimLen
			if finalIndex >= buf.length
				buf = buffers()
				return
		buf.splice 0, finalIndex if finalIndex > -1

	stream.write = (data, encoding) ->
		stream.emit "data", data
		data = new Buffer data, encoding if "string" is typeof data
		buf.push data
		doSplit()
		return true

	stream.end = (data, encoding) ->
		stream.write data, encoding if data
		stream.writable = false

		emitToken buf.toBuffer() if buf.length
		stream.emit "done"

		src and src.removeListener "error", srcErrorHandler

	# We log src stream fails if no one else is listening for them.
	srcErrorHandler = (err) ->
		stream.emit "error", err unless src.listeners("error").length > 1

	stream.on "pipe", (_src) ->
		src = _src
		src.on "error", srcErrorHandler

	return stream
