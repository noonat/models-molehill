package {
  import com.adobe.utils.AGALMiniAssembler;
  import com.phuce.Engine;
  import com.phuce.Utils;
  import com.phuce.obj.OBJ;
  import com.phuce.obj.OBJGroup;
  import flash.display3D.Context3D;
  import flash.display3D.Context3DProgramType;
  import flash.display3D.Context3DVertexBufferFormat;
  import flash.display3D.Program3D;
  import flash.geom.Matrix3D;
  import flash.geom.Vector3D;

  import flash.display.BitmapData;
  import flash.display3D.Context3DTextureFormat;
  import flash.display3D.textures.Texture;

  [SWF(width=640, height=480, backgroundColor="#000000")]
  public class DemoOBJ extends Engine {
    [Embed(source="../res/bunker/bunker.obj", mimeType="application/octet-stream")]
    static protected const BUNKER_OBJ:Class;
    [Embed(source="../res/bunker/fidget_head.png")]
    static protected const BUNKER_HEAD:Class;
    [Embed(source="../res/bunker/fidget_body.png")]
    static protected const BUNKER_BODY:Class;
    protected var _obj:OBJ;
    protected var _headBitmap:BitmapData;
    protected var _headTexture:Texture;
    protected var _bodyBitmap:BitmapData;
    protected var _bodyTexture:Texture;
    protected var _program:Program3D;
    protected var _fragmentConstants:Vector.<Number> = Vector.<Number>([
      0, -28, -64, 1,  // light position
      0.05,            // min light value
    ]);

    protected var _vertexShader:String = [
      "m44 op, va0, vc0",  // transform and output the position
      "m44 v0, va0, vc8",  // transform and copy the position
      "m44 v1, va1, vc8",  // transform and copy the normal
      "mov v2, va2",       // copy the uv
    ].join("\n");

    protected var _fragmentShader:String = [
      // get dir from the fragment to the light
      "sub ft0, v0, fc0",
      "nrm ft0.xyz, ft0.xyz",
      // lambert shading: max(0, dot(normal, lightDir))
      "nrm ft1.xyz, v1.xyz",
      "dp3 ft2.x, ft0.xyz, ft1.xyz",
      "max ft2.x, ft2.x, fc1.x",
      // combine the shading with the texture
      "tex ft1, v2, fs0 <2d,clamp,linear>",
      "mul oc, ft1.xyz, ft2.x"
    ].join("\n");

    function DemoOBJ() {
      super();
    }

    override public function init():void {
      // Load the head texture
      _headBitmap = new BUNKER_HEAD().bitmapData;
      _headTexture = _context.createTexture(
        _headBitmap.width, _headBitmap.height, Context3DTextureFormat.BGRA, false);
      _headTexture.uploadFromBitmapData(_headBitmap);

      // Load the body texture
      _bodyBitmap = new BUNKER_BODY().bitmapData;
      _bodyTexture = _context.createTexture(
        _bodyBitmap.width, _bodyBitmap.height, Context3DTextureFormat.BGRA, false);
      _bodyTexture.uploadFromBitmapData(_bodyBitmap);

      // Load the model, and set the material textures
      _obj = new OBJ();
      _obj.readBytes(new BUNKER_OBJ(), _context);
      _obj.setMaterial('h_head', _headTexture);
      _obj.setMaterial('u_torso', _bodyTexture);
      _obj.setMaterial('l_legs', _bodyTexture);

      // Create a program from the two shaders
      var vsAssembler:AGALMiniAssembler = new AGALMiniAssembler;
      vsAssembler.assemble(Context3DProgramType.VERTEX, _vertexShader);
      var fsAssembler:AGALMiniAssembler = new AGALMiniAssembler;
      fsAssembler.assemble(Context3DProgramType.FRAGMENT, _fragmentShader);
      _program = _context.createProgram();
      _program.upload(vsAssembler.agalcode, fsAssembler.agalcode);
      _context.setProgram(_program);
    }

    override public function update():void {
      _context.clear(0.05, 0.05, 0.05);

      // Rotate the model
      _model.identity();
      _model.appendRotation(_time * 45, new Vector3D(0, 1, 0));

      // Move the camera back a bit
      _modelView.identity();
      _modelView.append(_model);
      _modelView.appendTranslation(0, -28, -64);

      // Merge it all with the projection matrix
      _modelViewProjection.identity();
      _modelViewProjection.append(_modelView);
      _modelViewProjection.append(_projection);

      // Set the program constants
      _context.setProgramConstantsFromMatrix(
        Context3DProgramType.VERTEX, 0, _modelViewProjection, true);
      _context.setProgramConstantsFromMatrix(
        Context3DProgramType.VERTEX, 8, _model, true);
      _context.setProgramConstantsFromVector(
        Context3DProgramType.FRAGMENT, 0, _fragmentConstants);

      // Draw the model
      _context.setVertexBufferAt(
        0, _obj.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
      _context.setVertexBufferAt(
        1, _obj.vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
      _context.setVertexBufferAt(
        2, _obj.vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_2);
      for each (var group:OBJGroup in _obj.groups) {
        _context.setTextureAt(0, _obj.getMaterial(group.materialName));
        _context.drawTriangles(group.indexBuffer);
      }

      _context.present();
    }
  }
}
