#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  cloud_firestore
  file_selector_windows
  firebase_auth
  firebase_core
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  firebase_storage
=======
  url_launcher_windows
>>>>>>> 15b7d0c790c990635a49d21c590eb0be943f3e83
=======
  url_launcher_windows
>>>>>>> 15b7d0c790c990635a49d21c590eb0be943f3e83
=======
  firebase_storage
  url_launcher_windows
>>>>>>> 4a00f2587222bc04c6ac9de0a90d9d1ad0f53e3c
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
