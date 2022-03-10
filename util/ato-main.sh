#!/bin/sh

hello
counter
check_for_app "ERROR" $runtime_dependencies
check_for_app $runtime_dependencies_optional
