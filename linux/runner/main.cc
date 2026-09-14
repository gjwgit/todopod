#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "my_application.h"

// 20260914 gjw Flutter 3.47 defaults Linux to the Impeller OpenGLES-SDF
// renderer, which draws stroked curves with no antialiasing on Mesa/Intel GPUs
// -- the busy spinner stair-steps and its stroke renders thinner than
// requested. Skia draws it correctly, so fall back to Skia until Impeller is
// fixed upstream. Remove once Impeller renders arcs smoothly -- Skia is slated
// for removal from the engine.
//
// The engine takes these switches from the environment, so this covers
// packaged builds too, where `--no-enable-impeller` is not available. We must
// APPEND rather than assign: `flutter run` populates the same variables with
// its own switches (enable-dart-profiling, the VM service port, ...), so
// overwriting them silently breaks debugging, and declining to overwrite makes
// this a no-op under `flutter run`. An existing enable-impeller switch is left
// alone so `flutter run --enable-impeller` still wins.

static void prefer_skia_renderer() {
  const char* count_value = getenv("FLUTTER_ENGINE_SWITCHES");
  int count = count_value != nullptr ? atoi(count_value) : 0;

  if (count < 0) {
    count = 0;
  }

  char name[64];

  for (int i = 1; i <= count; i++) {
    snprintf(name, sizeof(name), "FLUTTER_ENGINE_SWITCH_%d", i);
    const char* value = getenv(name);
    if (value != nullptr && strstr(value, "enable-impeller") != nullptr) {
      return;
    }
  }

  snprintf(name, sizeof(name), "FLUTTER_ENGINE_SWITCH_%d", count + 1);
  setenv(name, "enable-impeller=false", 1);

  char total[16];
  snprintf(total, sizeof(total), "%d", count + 1);
  setenv("FLUTTER_ENGINE_SWITCHES", total, 1);
}

int main(int argc, char** argv) {
  prefer_skia_renderer();

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
