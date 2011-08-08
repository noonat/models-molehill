package com.phuce {
  import flash.geom.Matrix3D;
  import flash.utils.ByteArray;

  public class Utils {
    static public function perspectiveProjection(
      fov:Number=90, aspect:Number=1, near:Number=1, far:Number=2048):Matrix3D {
      var y2:Number = near * Math.tan(fov * Math.PI / 360);
      var y1:Number = -y2;
      var x1:Number = y1 * aspect;
      var x2:Number = y2 * aspect;

      var a:Number = 2 * near / (x2 - x1);
      var b:Number = 2 * near / (y2 - y1);
      var c:Number = (x2 + x1) / (x2 - x1);
      var d:Number = (y2 + y1) / (y2 - y1);
      var q:Number = -(far + near) / (far - near);
      var qn:Number = -2 * (far * near) / (far - near);

      return new Matrix3D(Vector.<Number>([
        a, 0, 0, 0,
        0, b, 0, 0,
        c, d, q, -1,
        0, 0, qn, 0
      ]));
    }

    /**
    * Read an ASCII, zero-terminated C string from a byte array.
    * @param bytes Byte array to read from.
    * @param length Width of the string. This many bytes will be read, even
    *  if a zero is encountered sooner.
    */
    static public function readString(bytes:ByteArray, length:int):String {
      var string:String = '';
      for (var i:int = 0; i < length; ++i) {
        var byte:uint = bytes.readUnsignedByte();
        if (byte === 0) {
          bytes.position += Math.max(0, length - (i + 1));
          break;
        } else {
          string += String.fromCharCode(byte);
        }
      }
      return string;
    }

    /**
    * Return value if it is a power of two, or the next highest power of two.
    */
    static public function upperPowerOfTwo(value:uint):uint {
      value--;
      value |= value >> 1;
      value |= value >> 2;
      value |= value >> 4;
      value |= value >> 8;
      value |= value >> 16;
      value++;
      return value;
    }
  }
}
