
use ".."
use "schema"

actor Receiver
  var _buffer: String = ""
  let _handler: RequestHandler
  new create(handler: RequestHandler) => _handler = handler
  
  fun tag stdin_notify(): StdinNotify iso^ =>
    object iso is StdinNotify
      let reader: Receiver = this
      fun ref apply(data: Array[U8] iso) => reader.read_bytes(consume data)
      fun ref dispose()                  => reader.parse_buffer()
    end
  
  be read_bytes(data: Array[U8] iso) =>
    // TODO: integrate closer with data source and use `expect` to avoid adding.
    _buffer = _buffer + String.from_array(consume data)
  
  be parse_buffer() =>
    try
      let segments = CapnSegmentUtil.parse_table(_buffer)?
      let entity = CapnEntityPtrUtil.parse(segments, segments(0)?, 0)?
      let req = CodeGeneratorRequest(entity as CapnStructPtr)
      _handler(req)
    end
