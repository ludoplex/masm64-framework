#!/usr/bin/env python3
"""
Shellcode Extractor

Extracts raw shellcode bytes from compiled PE executable.
Outputs in various formats for testing and deployment.
"""

import sys
import struct

def extract_text_section(pe_path):
    """Extract .text section from PE file."""
    with open(pe_path, 'rb') as f:
        data = f.read()
    
    # Parse DOS header
    if data[:2] != b'MZ':
        raise ValueError("Not a valid PE file")
    
    e_lfanew = struct.unpack('<I', data[0x3C:0x40])[0]
    
    # Parse PE header
    if data[e_lfanew:e_lfanew+4] != b'PE\x00\x00':
        raise ValueError("Invalid PE signature")
    
    # COFF header
    num_sections = struct.unpack('<H', data[e_lfanew+6:e_lfanew+8])[0]
    size_of_optional = struct.unpack('<H', data[e_lfanew+20:e_lfanew+22])[0]
    
    # Section headers start
    section_start = e_lfanew + 24 + size_of_optional
    
    # Find .text section
    for i in range(num_sections):
        section_offset = section_start + (i * 40)
        name = data[section_offset:section_offset+8].rstrip(b'\x00').decode('ascii')
        
        if name == '.text':
            virtual_size = struct.unpack('<I', data[section_offset+8:section_offset+12])[0]
            raw_offset = struct.unpack('<I', data[section_offset+20:section_offset+24])[0]
            raw_size = struct.unpack('<I', data[section_offset+16:section_offset+20])[0]
            
            # Extract section data
            section_data = data[raw_offset:raw_offset+min(virtual_size, raw_size)]
            return section_data
    
    raise ValueError(".text section not found")

def output_c_array(shellcode, var_name="shellcode"):
    """Output as C byte array."""
    lines = [f"unsigned char {var_name}[] = {{"]
    for i in range(0, len(shellcode), 12):
        chunk = shellcode[i:i+12]
        hex_bytes = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f"    {hex_bytes},")
    lines.append("};")
    lines.append(f"unsigned int {var_name}_len = {len(shellcode)};")
    return '\n'.join(lines)

def output_python(shellcode, var_name="shellcode"):
    """Output as Python bytes."""
    hex_str = shellcode.hex()
    return f'{var_name} = bytes.fromhex("{hex_str}")'

def output_hex(shellcode):
    """Output as hex string."""
    return shellcode.hex()

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <pe_file> [output_format]")
        print("Formats: raw, c, python, hex (default: raw)")
        sys.exit(1)
    
    pe_path = sys.argv[1]
    output_format = sys.argv[2] if len(sys.argv) > 2 else "raw"
    
    try:
        shellcode = extract_text_section(pe_path)
        print(f"[+] Extracted {len(shellcode)} bytes", file=sys.stderr)
        
        if output_format == "raw":
            output_path = pe_path.rsplit('.', 1)[0] + '.bin'
            with open(output_path, 'wb') as f:
                f.write(shellcode)
            print(f"[+] Written to {output_path}", file=sys.stderr)
        elif output_format == "c":
            print(output_c_array(shellcode))
        elif output_format == "python":
            print(output_python(shellcode))
        elif output_format == "hex":
            print(output_hex(shellcode))
        else:
            print(f"Unknown format: {output_format}", file=sys.stderr)
            sys.exit(1)
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

