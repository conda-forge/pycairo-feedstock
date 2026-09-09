"""Exercise the installed extension and verify native Windows binaries."""
import io
import struct
import sys
import sysconfig
from pathlib import Path

import cairo
from cairo import _cairo

if sysconfig.get_config_var("Py_GIL_DISABLED"):
    assert not sys._is_gil_enabled(), "Pycairo unexpectedly enabled the GIL"
    print("Free-threaded Python: GIL remains disabled")

expected = int(sys.argv[1], 16)
for path in (Path(sys.executable), Path(_cairo.__file__)):
    data = path.read_bytes()
    assert data[:2] == b"MZ", path
    pe_offset = struct.unpack_from("<I", data, 60)[0]
    assert data[pe_offset:pe_offset + 4] == b"PE\0\0", path
    machine = struct.unpack_from("<H", data, pe_offset + 4)[0]
    assert machine == expected, (path, hex(machine), hex(expected))
    print(f"{path}: PE machine {machine:04X}")

for invalid in (-1, -2147483648, 2147483647):
    try:
        cairo.PSSurface.level_to_string(invalid)
    except ValueError:
        pass
    else:
        raise AssertionError(f"Accepted invalid PostScript level {invalid}")

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 16, 16)
context = cairo.Context(surface)
context.set_source_rgb(1, 0, 0)
context.paint()
context.set_source_rgb(0, 0, 1)
context.rectangle(8, 0, 8, 16)
context.fill()
surface.flush()

def pixel(image, x, y):
    offset = y * image.get_stride() + x * 4
    return int.from_bytes(image.get_data()[offset:offset + 4], sys.byteorder)

assert pixel(surface, 2, 2) == 0xFFFF0000
assert pixel(surface, 12, 2) == 0xFF0000FF
png = io.BytesIO()
surface.write_to_png(png)
assert png.getvalue().startswith(b"\x89PNG\r\n\x1a\n")
png.seek(0)
restored = cairo.ImageSurface.create_from_png(png)
assert restored.get_width() == restored.get_height() == 16
assert pixel(restored, 2, 2) == 0xFFFF0000
assert pixel(restored, 12, 2) == 0xFF0000FF

for surface_type, marker in ((cairo.PDFSurface, b"%PDF-"), (cairo.SVGSurface, b"<svg")):
    output = io.BytesIO()
    vector = surface_type(output, 16, 16)
    pen = cairo.Context(vector)
    pen.set_source_rgb(0, 1, 0)
    pen.rectangle(1, 1, 10, 10)
    pen.fill()
    vector.finish()
    assert marker in output.getvalue(), surface_type

print(f"Installed Pycairo {cairo.version}, Cairo {cairo.cairo_version_string()}: drawing, PNG, PDF, and SVG passed")
