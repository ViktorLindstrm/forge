These are the SVG frames I generated for a short GIF-like demo. To make a GIF locally, run one of the following commands in the repository root after installing the required tool.

Option A (gifski - higher quality):

gifski -o docs/demo-create-project.gif docs/gif-frame-*.svg

Option B (ffmpeg):

ffmpeg -y -framerate 1 -i docs/gif-frame-%02d.svg -vf "scale=900:-1:flags=lanczos" docs/demo-create-project.gif

Adjust framerate (e.g. -framerate 2) for smoother animation.
