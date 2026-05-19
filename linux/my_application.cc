#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <cstring>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

#include <bitsdojo_window_linux/bitsdojo_window_plugin.h>

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void respond_with_error(FlMethodCall* method_call,
                               const gchar* code,
                               const gchar* message) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
      fl_method_error_response_new(code, message, nullptr));
  fl_method_call_respond(method_call, response, nullptr);
}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  (void)channel;
  (void)user_data;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "decode-heif") != 0) {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
        fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  FlValue* args = fl_method_call_get_args(method_call);
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    respond_with_error(method_call, "bad-args", "Expected argument map");
    return;
  }

  FlValue* file_value = fl_value_lookup_string(args, "file");
  FlValue* output_value = fl_value_lookup_string(args, "output");
  if (file_value == nullptr || output_value == nullptr ||
      fl_value_get_type(file_value) != FL_VALUE_TYPE_STRING ||
      fl_value_get_type(output_value) != FL_VALUE_TYPE_STRING) {
    respond_with_error(method_call, "bad-args", "Missing file or output path");
    return;
  }

  const gchar* input_path = fl_value_get_string(file_value);
  const gchar* output_path = fl_value_get_string(output_value);

  g_autoptr(GError) error = nullptr;
  g_autoptr(GdkPixbuf) pixbuf = gdk_pixbuf_new_from_file(input_path, &error);
  if (pixbuf == nullptr) {
    respond_with_error(method_call, "decode-failed", error->message);
    return;
  }

  if (!gdk_pixbuf_save(pixbuf, output_path, "png", &error, nullptr)) {
    respond_with_error(method_call, "encode-failed", error->message);
    return;
  }

  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  fl_method_call_respond(method_call, response, nullptr);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "bluebubbles_app");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    auto bdw = bitsdojo_window_from(window);
    bdw->setCustomFrame(true);
    gtk_window_set_title(window, "bluebubbles_app");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_realize(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(
      messenger, "com.bluebubbles.messaging", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
