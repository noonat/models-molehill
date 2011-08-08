package com.phuce.obj {
  import flash.display3D.IndexBuffer3D;

  public class OBJGroup {
    public var name:String;
    public var materialName:String;
    public var indexBuffer:IndexBuffer3D;

    internal var _faces:Vector.<Vector.<String>>;
    internal var _indices:Vector.<uint>;

    function OBJGroup(name:String=null, materialName:String=null) {
      this.name = name;
      this.materialName = materialName;
      _faces = new Vector.<Vector.<String>>();
      _indices = new Vector.<uint>();
    }

    public function dispose():void {
      if (indexBuffer != null) {
        indexBuffer.dispose();
        indexBuffer = null;
      }
      _faces.length = 0;
      _indices.length = 0;
    }
  }
}
