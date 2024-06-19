#!/bin/bash
docker run --rm -v $(pwd):/build ubuntu sh -c "cd /build  && ./update.sh"
