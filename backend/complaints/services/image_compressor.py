import io
from PIL import Image
from django.core.files.uploadedfile import InMemoryUploadedFile

def compress_image(uploaded_file, max_width: int = 1600, max_height: int = 1600, quality: int = 80) -> InMemoryUploadedFile:
    """
    Resizes and compresses an uploaded image using Pillow to save disk & bandwidth.
    """
    try:
        img = Image.open(uploaded_file)
        
        # Convert RGBA / P modes to RGB for JPEG compatibility
        if img.mode in ('RGBA', 'P'):
            img = img.convert('RGB')

        # Maintain aspect ratio resize if larger than max dimensions
        img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

        output_io = io.BytesIO()
        img.save(output_io, format='JPEG', quality=quality, optimize=True)
        output_io.seek(0)

        filename = f"compressed_{uploaded_file.name.rsplit('.', 1)[0]}.jpg"

        return InMemoryUploadedFile(
            output_io,
            'ImageField',
            filename,
            'image/jpeg',
            output_io.getbuffer().nbytes,
            None
        )
    except Exception as e:
        # If compression fails, return original file
        uploaded_file.seek(0)
        return uploaded_file
