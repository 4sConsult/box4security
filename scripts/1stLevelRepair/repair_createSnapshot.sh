# Called by web application - creates snapshot at /var/lib/box4s/snapshots/
# Create dir if not present
timestamp=$(date +%d-%m-%Y_%H-%M-%S)
Snaplocation="/var/lib/box4s/snapshots"
name="Snapshot-$timestamp.zip"
filename="$Snaplocation/$name"
echo 123 > $filename
