param(
    [string]$ProtoFile
)

$OutDir = "generated"

New-Item -ItemType Directory -Force $OutDir | Out-Null
New-Item -ItemType File -Force "$OutDir\__init__.py" | Out-Null

python -m grpc_tools.protoc `
    -I (Split-Path $ProtoFile -Parent) `
    --python_out=$OutDir `
    --grpc_python_out=$OutDir `
    $ProtoFile