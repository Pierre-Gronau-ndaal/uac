# Copyright (C) 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# shellcheck disable=SC2006

###############################################################################

###############################################################################
hash_wrapper()
{
  # some systems such as Solaris 10 do not support more than 9 parameters
  # on functions, not even using curly braces {} e.g. ${10}
  # so the solution was to use shift
  hw_path="${1:-}"
  shift
  hw_is_file_list="${1:-false}"
  shift
  hw_path_pattern="${1:-}"
  shift
  hw_name_pattern="${1:-}"
  shift
  hw_exclude_path_pattern="${1:-}"
  shift
  hw_exclude_name_pattern="${1:-}"
  shift
  hw_max_depth="${1:-}"
  shift
  hw_file_type="${1:-}"
  shift
  hw_min_file_size="${1:-}"
  shift
  hw_max_file_size="${1:-}"
  shift
  hw_permissions="${1:-}"
  shift
  hw_ignore_date_range="${1:-false}"
  shift
  hw_hash_algorithm="${1:-md5}"
  
  # return if path is empty
  if [ -z "${hw_path}" ]; then
    printf %b "hash_wrapper: missing required argument: 'path'\n" >&2
    return 22
  fi

  # return if is file list and file list does not exist
  if ${hw_is_file_list} && [ ! -f "${hw_path}" ]; then
    printf %b "hash_wrapper: file list does not exist: '${hw_path}'\n" >&2
    return 5
  fi

  ${hw_ignore_date_range} && hw_date_range_start_days="" \
    || hw_date_range_start_days="${START_DATE_DAYS}"
  ${hw_ignore_date_range} && hw_date_range_end_days="" \
    || hw_date_range_end_days="${END_DATE_DAYS}"

  if [ "${hw_hash_algorithm}" = "md5" ] && [ -n "${MD5_HASHING_TOOL}" ]; then
    hw_hashing_tool="${MD5_HASHING_TOOL}"
  elif [ "${hw_hash_algorithm}" = "sha1" ] && [ -n "${SHA1_HASHING_TOOL}" ]; then
    hw_hashing_tool="${SHA1_HASHING_TOOL}"
  elif [ "${hw_hash_algorithm}" = "sha256" ] && [ -n "${SHA256_HASHING_TOOL}" ]; then
    hw_hashing_tool="${SHA256_HASHING_TOOL}"   
  else
    printf %b "hash_wrapper: algorithm not supported '${hw_hash_algorithm}'\n" >&2
    return 1
  fi

  if ${XARGS_REPLACE_STRING_SUPPORT}; then
    if ${hw_is_file_list}; then
      log_message COMMAND "sort -u \"${hw_path}\" | sed -e \"s:':\\\':g\" -e 's:\":\\\\\":g' | xargs -I{} ${hw_hashing_tool} \"{}\""
      # sort and uniq
      # escape single and double quotes
      # shellcheck disable=SC2086
      sort -u "${hw_path}" \
        | sed -e "s:':\\\':g" -e 's:":\\\":g' \
        | xargs -I{} ${hw_hashing_tool} "{}"
    else
      # find
      # sort and uniq
      # escape single and double quotes
      # shellcheck disable=SC2086
      find_wrapper \
        "${hw_path}" \
        "${hw_path_pattern}" \
        "${hw_name_pattern}" \
        "${hw_exclude_path_pattern}" \
        "${hw_exclude_name_pattern}" \
        "${hw_max_depth}" \
        "${hw_file_type}" \
        "${hw_min_file_size}" \
        "${hw_max_file_size}" \
        "${hw_permissions}" \
        "${hw_date_range_start_days}" \
        "${hw_date_range_end_days}" \
        | sort -u \
        | sed -e "s:':\\\':g" -e 's:":\\\":g' \
        | xargs -I{} ${hw_hashing_tool} "{}"
      log_message COMMAND "| sort -u | sed -e \"s:':\\\':g\" -e 's:\":\\\\\":g' | xargs -I{} ${hw_hashing_tool} \"{}\""
    fi
  else
    if ${hw_is_file_list}; then
      log_message COMMAND "sort -u \"${hw_path}\" | while read %line%; do ${hw_hashing_tool} \"%line%\""
      # shellcheck disable=SC2162
      sort -u "${hw_path}" \
        | while read hw_line || [ -n "${hw_line}" ]; do
            ${hw_hashing_tool} "${hw_line}"
          done
    else
      # shellcheck disable=SC2162
      find_wrapper \
        "${hw_path}" \
        "${hw_path_pattern}" \
        "${hw_name_pattern}" \
        "${hw_exclude_path_pattern}" \
        "${hw_exclude_name_pattern}" \
        "${hw_max_depth}" \
        "${hw_file_type}" \
        "${hw_min_file_size}" \
        "${hw_max_file_size}" \
        "${hw_permissions}" \
        "${hw_date_range_start_days}" \
        "${hw_date_range_end_days}" \
        | sort -u \
        | while read hw_line || [ -n "${hw_line}" ]; do
            ${hw_hashing_tool} "${hw_line}"
          done
      log_message COMMAND "| sort -u | while read %line%; do ${hw_hashing_tool} \"%line%\""
    fi
  fi

}