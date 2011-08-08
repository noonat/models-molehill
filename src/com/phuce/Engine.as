package com.phuce {
  import com.adobe.utils.AGALMiniAssembler;
  import flash.display.Sprite;
  import flash.display.Stage3D;
  import flash.display.StageAlign;
  import flash.display.StageScaleMode;
  import flash.display3D.Context3D;
  import flash.display3D.Context3DCompareMode;
  import flash.display3D.Context3DProgramType;
  import flash.display3D.Context3DRenderMode;
  import flash.display3D.Context3DTriangleFace;
  import flash.display3D.Context3DVertexBufferFormat;
  import flash.display3D.IndexBuffer3D;
  import flash.display3D.Program3D;
  import flash.display3D.VertexBuffer3D;
  import flash.events.Event;
  import flash.geom.Matrix3D;
  import flash.geom.Rectangle;
  import flash.geom.Vector3D;
  import flash.utils.getTimer;

  public class Engine extends Sprite {
    protected var _width:Number;
    protected var _height:Number;

    protected var _stage:Stage3D;
    protected var _context:Context3D;

    protected var _model:Matrix3D;
    protected var _modelView:Matrix3D;
    protected var _modelViewProjection:Matrix3D;
    protected var _projection:Matrix3D;

    protected var _time:Number = 0;
    protected var _deltaTime:Number = 0;

    function Engine() {
      if (stage) {
        onAddedToStage();
      } else {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
      }
    }

    /**
    * Override this. Called when the 3D context is ready.
    */
    public function init():void {

    }

    /**
    * Override this. Called each frame.
    */
    public function update():void {

    }

    protected function onAddedToStage(event:Event=null):void {
      removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
      stage.align = StageAlign.TOP_LEFT;
      stage.scaleMode = StageScaleMode.NO_SCALE;

      _width = stage.stageWidth;
      _height = stage.stageHeight;

      _stage = stage.stage3Ds[0];
      _stage.addEventListener(Event.CONTEXT3D_CREATE, onContext);
      _stage.requestContext3D(Context3DRenderMode.AUTO);
    }

    protected function onContext(event:Event):void {
      _context = _stage.context3D;
      _context.configureBackBuffer(_width, _height, 2, true);
      _context.enableErrorChecking = true;

      // Discard triangles pointing away from the camera, and ones
      // behind things that we've already drawn.
      _context.setCulling(Context3DTriangleFace.BACK);
      _context.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);

      // Setup our initial matrices.
      _model = new Matrix3D();
      _modelView = new Matrix3D();
      _modelViewProjection = new Matrix3D();
      _projection = Utils.perspectiveProjection(60, _width / _height, 0.1, 2048);

      init();

      _time = getTimer() / 1000.0;
      addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    protected function onEnterFrame(event:Event):void {
      var newTime:Number = getTimer() / 1000;
      _deltaTime = newTime - _time;
      _time = newTime;

      update();
    }
  }
}
