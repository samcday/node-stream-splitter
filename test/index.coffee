StreamSplitter = require "../src/splitter.coffee"
fs = require "fs"
path = require "path"
# Dropper = require "dropper"

textFile = path.join __dirname, "fixtures", "textfile.txt"
binaryFile = path.join __dirname, "fixtures", "binaryfile.blob"

describe "StreamSplitter", ->
	it "splits text stream correctly with string delimiter", (done) ->
		splitter = fs.createReadStream(textFile).pipe StreamSplitter "\n"

		tokens = []
		splitter.on "token", (token) -> tokens.push token.toString()
		splitter.on "done", ->
			tokens.should.eql ["These", "are", "tokens", "dude."]
			done()
	it "splits text stream correctly with binary delimiter", (done) ->
		delim = new Buffer("\n")
		splitter = fs.createReadStream(textFile).pipe StreamSplitter delim
		tokens = []
		splitter.on "token", (token) -> tokens.push token.toString()
		splitter.on "done", ->
			tokens.should.eql ["These", "are", "tokens", "dude."]
			done()
	it "gives out tokens in requested encoding", (done) ->
		splitter = fs.createReadStream(textFile).pipe StreamSplitter "\n"
		splitter.encoding = "utf8"
		splitter.once "token", (token) ->
			token.should.be.a "string"
			done()
	it "splits binary stream correctly", (done) ->
		splitter = fs.createReadStream(binaryFile).pipe StreamSplitter "\0"
		octets = []
		splitter.on "token", (token) ->
			token.length.should.be.equal 1
			octets.push token[0]
		splitter.on "done", ->
			octets.should.eql [1, 2, 3, 255]
			done()
	# it "splits correctly with drip-fed text stream", (done) ->
	# 	dropper = new Dropper 1
	# 	splitter = fs.createReadStream(textFile).pipe(dropper)
	# 		.pipe(StreamSplitter "\n")

	# 	tokens = []
	# 	splitter.on "token", (token) -> tokens.push token.toString()
	# 	splitter.on "done", ->
	# 		tokens.should.eql ["These", "are", "tokens", "dude."]
	# 		done()
	# it "splits binary stream correctly", (done) ->
	# 	dropper = new Dropper 1
	# 	splitter = fs.createReadStream(binaryFile).pipe(dropper)
	# 		.pipe StreamSplitter "\0"
	# 	octets = []
	# 	splitter.on "token", (token) ->
	# 		token.length.should.be.equal 1
	# 		octets.push token[0]
	# 	splitter.on "done", ->
	# 		octets.should.eql [1, 2, 3, 255]
	# 		done()
	it "doesn't freak out when not being piped to", (done) ->
		splitter = StreamSplitter "\n"
		splitter.on "done", ->
			done()
		splitter.end()

	it "splits an ended stream properly", (done) ->
		splitter = StreamSplitter "\n"
		splitter.encoding = "utf8"
		gotToken = false
		splitter.on "token", (token) ->
			token.should.eql "Hello"
			gotToken = true
		splitter.on "done", ->
			gotToken.should.be.true
			done()
		splitter.write "Hello"
		splitter.end()
	it "still emits data events", (done) ->
		splitter = StreamSplitter ","
		splitter.encoding = "utf8"
		tokens = []
		dataEmitted = false
		splitter.on "token", (token) ->
			tokens.push token
		splitter.on "done", ->
			tokens.should.eql ["Hello", "World"]
			dataEmitted.should.be.true
			done()
		splitter.on "data", (data) ->
			data.should.eql "Hello,World"
			dataEmitted = true
		splitter.write "Hello,World"
		splitter.end()
