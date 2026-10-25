
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

source_dir = Path("build/package")
zip_path = Path("build/lambda-deployment-v2.zip")

with ZipFile(zip_path, "w", ZIP_DEFLATED) as archive:
    for file in source_dir.rglob("*"):
        if file.is_file():
            archive.write(
                file,
                arcname=file.relative_to(source_dir).as_posix()
            )

print("Lambda ZIP created successfully!")
print(f"Size: {zip_path.stat().st_size / (1024 * 1024):.2f} MiB")
