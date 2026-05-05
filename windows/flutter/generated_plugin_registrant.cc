//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <cloud_firestore/cloud_firestore_plugin_c_api.h>
#include <file_selector_windows/file_selector_windows.h>
#include <firebase_auth/firebase_auth_plugin_c_api.h>
#include <firebase_core/firebase_core_plugin_c_api.h>
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
#include <firebase_storage/firebase_storage_plugin_c_api.h>
=======
#include <url_launcher_windows/url_launcher_windows.h>
>>>>>>> 15b7d0c790c990635a49d21c590eb0be943f3e83
=======
#include <url_launcher_windows/url_launcher_windows.h>
>>>>>>> 15b7d0c790c990635a49d21c590eb0be943f3e83
=======
#include <firebase_storage/firebase_storage_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>
>>>>>>> 4a00f2587222bc04c6ac9de0a90d9d1ad0f53e3c

void RegisterPlugins(flutter::PluginRegistry* registry) {
  CloudFirestorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CloudFirestorePluginCApi"));
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  FirebaseAuthPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  FirebaseStoragePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseStoragePluginCApi"));
=======
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
>>>>>>> 15b7d0c790c990635a49d21c590eb0be943f3e83
=======
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
>>>>>>> 15b7d0c790c990635a49d21c590eb0be943f3e83
=======
  FirebaseStoragePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseStoragePluginCApi"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
>>>>>>> 4a00f2587222bc04c6ac9de0a90d9d1ad0f53e3c
}
