#!/usr/bin/env python3
"""
EDRTest Shellcode Extractor
Extracts raw shellcode bytes from compiled executable

Usage: python extract.py edrtest.exe output.bin
"""

import sys
import struct

def extract_shellcode(exe_path, output_path):
    """Extract .text section from PE file as raw shellcode"""
    
    with open(exe_path, 'rb') as f:
        data = f.read()
    
    # Check MZ header
    if data[:2] != b'MZ':
        print("Error: Not a valid PE file")
        return False
    
    # Get PE header offset
    pe_offset = struct.unpack('<I', data[0x3C:0x40])[0]
    
    # Check PE signature
    if data[pe_offset:pe_offset+4] != b'PE\x00\x00':
        print("Error: Invalid PE signature")
        return False
    
    # Parse COFF header
    coff_offset = pe_offset + 4
    num_sections = struct.unpack('<H', data[coff_offset+2:coff_offset+4])[0]
    optional_header_size = struct.unpack('<H', data[coff_offset+16:coff_offset+18])[0]
    
    # Section headers start after optional header
    section_offset = coff_offset + 20 + optional_header_size
    
    # Find .text section
    text_section = None
    for i in range(num_sections):
        section_start = section_offset + (i * 40)
        section_name = data[section_start:section_start+8].rstrip(b'\x00')
        
        if section_name == b'.text':
            virtual_size = struct.unpack('<I', data[section_start+8:section_start+12])[0]
            raw_offset = struct.unpack('<I', data[section_start+20:section_start+24])[0]
            raw_size = struct.unpack('<I', data[section_start+16:section_start+20])[0]
            
            text_section = {
                'virtual_size': virtual_size,
                'raw_offset': raw_offset,
                'raw_size': raw_size
            }
            break
    
    if not text_section:
        print("Error: .text section not found")
        return False
    
    # Extract shellcode bytes
    shellcode = data[text_section['raw_offset']:
                     text_section['raw_offset'] + text_section['virtual_size']]
    
    # Trim trailing zeros (padding)
    while shellcode and shellcode[-1] == 0:
        shellcode = shellcode[:-1]
    
    # Write output
    with open(output_path, 'wb') as f:
        f.write(shellcode)
    
    print(f"Extracted {len(shellcode)} bytes of shellcode")
    print(f"Output: {output_path}")
    
    # Print hex dump of first 64 bytes
    print("\nFirst 64 bytes:")
    for i in range(0, min(64, len(shellcode)), 16):
        hex_str = ' '.join(f'{b:02x}' for b in shellcode[i:i+16])
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in shellcode[i:i+16])
        print(f"  {i:04x}: {hex_str:<48} {ascii_str}")
    
    # Generate C array format
    c_output = output_path.rsplit('.', 1)[0] + '.h'
    with open(c_output, 'w') as f:
        f.write("// EDRTest shellcode - auto-generated\n")
        f.write(f"// Size: {len(shellcode)} bytes\n\n")
        f.write("unsigned char shellcode[] = {\n    ")
        for i, b in enumerate(shellcode):
            if i > 0 and i % 16 == 0:
                f.write("\n    ")
            f.write(f"0x{b:02x}")
            if i < len(shellcode) - 1:
                f.write(", ")
        f.write("\n};\n")
        f.write(f"unsigned int shellcode_len = {len(shellcode)};\n")
    
    print(f"\nC header: {c_output}")
    
    return True

def main():
    if len(sys.argv) != 3:
        print("Usage: python extract.py <input.exe> <output.bin>")
        print("\nExtracts raw shellcode from compiled PE executable")
        sys.exit(1)
    
    success = extract_shellcode(sys.argv[1], sys.argv[2])
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

