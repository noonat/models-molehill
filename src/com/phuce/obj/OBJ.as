package com.phuce.obj {
  import flash.display3D.Context3D;
  import flash.display3D.textures.Texture;
  import flash.display3D.VertexBuffer3D;
  import flash.utils.ByteArray;
  import flash.utils.Dictionary;

  public class OBJ {
    public var name:String;
    public var groups:Vector.<OBJGroup>;
    public var vertexBuffer:VertexBuffer3D;
    
    protected var _materials:Dictionary;
    protected var _tupleIndex:uint;
    protected var _tupleIndices:Dictionary;
    protected var _vertices:Vector.<Number>;

    function OBJ() {
      groups = new Vector.<OBJGroup>();
      _materials = new Dictionary();
      _vertices = new Vector.<Number>();
    }

    public function getMaterial(name:String):Texture {
      return _materials[name];
    }

    public function setMaterial(name:String, texture:Texture):void {
      _materials[name] = texture;
    }

    public function dispose():void {
      for each (var group:OBJGroup in groups) {
        group.dispose();
      }
      groups.length = 0;
      if (vertexBuffer !== null) {
        vertexBuffer.dispose();
        vertexBuffer = null;
      }
      _vertices.length = 0;
      _tupleIndex = 0;
      _tupleIndices = new Dictionary();
    }

    public function readBytes(bytes:ByteArray, context:Context3D):void {
      dispose();

      var face:Vector.<String>;
      var group:OBJGroup;
      var materialName:String;
      var positions:Vector.<Number> = new Vector.<Number>();
      var normals:Vector.<Number> = new Vector.<Number>();
      var uvs:Vector.<Number> = new Vector.<Number>();

      bytes.position = 0;
      var text:String = bytes.readUTFBytes(bytes.bytesAvailable);
      var lines:Array = text.split(/[\r\n]+/);
      for each (var line:String in lines) {
        // Trim whitespace from the line
        line = line.replace(/^\s*|\s*$/g, '');
        if (line == '' || line.charAt(0) === '#') {
          // Blank line or comment, ignore it
          continue;
        }

        // Split line into fields on whitespace
        var fields:Array = line.split(/\s+/);
        switch (fields[0].toLowerCase()) {
          // Vertex position
          case 'v':
            positions.push(
              parseFloat(fields[1]),
              parseFloat(fields[2]),
              parseFloat(fields[3]));
            break;

          // Vertex normal
          case 'vn':
            normals.push(
              parseFloat(fields[1]),
              parseFloat(fields[2]),
              parseFloat(fields[3]));
            break;

          // Vertex UV
          case 'vt':
            uvs.push(
              parseFloat(fields[1]),
              1.0 - parseFloat(fields[2]));
            break;

          // Face indices, specified in sets of "position/uv/normal"
          case 'f':
            face = new Vector.<String>();
            for each (var tuple:String in fields.slice(1)) {
              face.push(tuple);
            }
            if (group === null) {
              group = new OBJGroup(null, materialName);
              groups.push(group);
            }
            group._faces.push(face);
            break;

          // New group, with a name
          case 'g':
            group = new OBJGroup(fields[1], materialName);
            groups.push(group);
            break;

          // Object name. The OBJ will only have one object statement.
          case 'o':
            name = fields[1];
            break;

          // Material library. I'm not handling this for now, Instead call
          // setMaterial() for each of the named materials.
          case 'mtllib':
            break;

          // Specifies the material for the current group (and any future
          // groups that don't have their own usemtl statement)
          case 'usemtl':
            materialName = fields[1];
            if (group !== null) {
              group.materialName = materialName;
            }
            break;
        }
      }

      // Normalize the vertices. OBJ does two things that cause problems for
      // modern renderers: it allows faces to be polygons, instead of only
      // triangles; and it allows each face vertex to have a different index
      // for each stream (position, normal, uv).
      //
      // This code creates triangle fans out of any faces that have more than
      // three vertexes, and merges distinct groupings of pos/normal/uv into
      // a single vertex stream.
      //
      for each (group in groups) {
        group._indices.length = 0;
        for each (face in group._faces) {
          var il:int = face.length - 1;
          for (var i:int = 1; i < il; ++i) {
            group._indices.push(mergeTuple(face[i], positions, normals, uvs));
            group._indices.push(mergeTuple(face[0], positions, normals, uvs));
            group._indices.push(mergeTuple(face[i + 1], positions, normals, uvs));
          }
        }
        group.indexBuffer = context.createIndexBuffer(group._indices.length);
        group.indexBuffer.uploadFromVector(group._indices, 0, group._indices.length);
        group._faces = null;
      }
      _tupleIndex = 0;
      _tupleIndices = null;

      vertexBuffer = context.createVertexBuffer(_vertices.length / 8, 8);
      vertexBuffer.uploadFromVector(_vertices, 0, _vertices.length / 8);
    }

    protected function mergeTuple(tuple:String, positions:Vector.<Number>, normals:Vector.<Number>, uvs:Vector.<Number>):uint {
      if (_tupleIndices[tuple] !== undefined) {
        // Already merged, return the merged index
        return _tupleIndices[tuple];
      } else {
        var faceIndices:Array = tuple.split('/');

        // Position index
        var index:uint = parseInt(faceIndices[0], 10) - 1;
        _vertices.push(
          positions[index * 3 + 0],
          positions[index * 3 + 1],
          positions[index * 3 + 2]);

        // Normal index
        if (faceIndices.length > 2 && faceIndices[2].length > 0) {
          index = parseInt(faceIndices[2], 10) - 1;
          _vertices.push(
            normals[index * 3 + 0],
            normals[index * 3 + 1],
            normals[index * 3 + 2]);
        } else {
          // Face doesn't have a normal
          _vertices.push(0, 0, 0);
        }

        // UV index
        if (faceIndices.length > 1 && faceIndices[1].length > 0) {
          index = parseInt(faceIndices[1], 10) - 1;
          _vertices.push(
            uvs[index * 2 + 0],
            uvs[index * 2 + 1]);
        } else {
          // Face doesn't have a UV
          _vertices.push(0, 0);
        }

        // Cache the merged tuple index in case it's used again
        return _tupleIndices[tuple] = _tupleIndex++;
      }
    }
  }
}
