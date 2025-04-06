# -*- coding: utf-8 -*-
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import logging
import os

logger = logging.getLogger()
logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
logger.info("!!! Loading configuration from /app/config/superset_config.py !!!")
logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

# ----------------------------------------------------
# DATABASE CONFIGURATION
# ----------------------------------------------------
# The database URI for Superset's metadata database.
# IMPORTANT: Use this setting to configure your PostgreSQL connection.
SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://superset:superset@superset_db:5432/superset"
logger.info(f"SQLALCHEMY_DATABASE_URI set to: {SQLALCHEMY_DATABASE_URI}")

# ----------------------------------------------------
# Optional: You can define other configurations here if needed
# ----------------------------------------------------
# Example: Set the webserver base URL if running behind a proxy
# WEBDRIVER_BASEURL = "http://superset:8088/"

# Example: Enable specific feature flags
# FEATURE_FLAGS = {
#     "ENABLE_TEMPLATE_PROCESSING": True,
# }
# SQLLAB_TIMEOUT = 300

# SUPERSET_TIMEOUT = 300

# CHART_TIMEOUT = 300

# Example: Configure caching (though Redis is removed in this setup)
# CACHE_CONFIG = {
#     'CACHE_TYPE': 'SimpleCache',
#     'CACHE_DEFAULT_TIMEOUT': 300
# }

# You MUST keep the SECRET_KEY configuration, but it's often better
# managed via environment variables for security. The environment variable
# SUPERSET_SECRET_KEY set in docker-compose will usually override this file.
# SECRET_KEY = "YOUR_OWN_RANDOM_SECRET_KEY_CHANGE_ME_IN_ENV_VAR"

logger.info("!!! Finished loading /app/config/superset_config.py !!!")