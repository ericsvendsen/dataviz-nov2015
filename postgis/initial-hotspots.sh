#!/bin/bash

# Create database for mosaic use
psql -c "DROP DATABASE hotspots;"
psql -c "CREATE DATABASE hotspots;"
psql -c "CREATE EXTENSION postgis;" hotspots
psql -c "CREATE SCHEMA hotspots;" hotspots
