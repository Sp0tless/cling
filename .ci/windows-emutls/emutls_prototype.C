#include <iostream>
#include <thread>

thread_local int tls_x = 1;
thread_local int tls_y = 2;

int guarded_init_count = 0;
int make_guarded_value() { ++guarded_init_count; return 77; }
int& guarded_value() { static int value = make_guarded_value(); return value; }

void emutls_prototype() {
  bool emutls_ok = true;
  void* main_x_address = &tls_x;
  void* main_y_address = &tls_y;

  if (main_x_address == main_y_address || tls_x != 1 || tls_y != 2)
    emutls_ok = false;

  tls_x = 11;

  void* worker_a_x_address = nullptr;
  void* worker_b_x_address = nullptr;
  int worker_a_x = 0;
  int worker_b_x = 0;
  int guarded_a = 0;
  int guarded_b = 0;

  std::thread a([&] {
    worker_a_x_address = &tls_x;
    tls_x = 21;
    worker_a_x = tls_x;
    guarded_a = guarded_value();
  });
  std::thread b([&] {
    worker_b_x_address = &tls_x;
    tls_x = 31;
    worker_b_x = tls_x;
    guarded_b = guarded_value();
  });
  a.join();
  b.join();

  if (worker_a_x_address == main_x_address ||
      worker_b_x_address == main_x_address ||
      worker_a_x_address == worker_b_x_address ||
      worker_a_x != 21 || worker_b_x != 31 || tls_x != 11 || tls_y != 2 ||
      guarded_a != 77 || guarded_b != 77 || guarded_init_count != 1)
    emutls_ok = false;

  std::cout << "main TLS: " << main_x_address << '=' << tls_x << '\n';
  std::cout << "worker TLS: " << worker_a_x_address << '=' << worker_a_x
            << " | " << worker_b_x_address << '=' << worker_b_x << '\n';
  std::cout << "guarded static: " << guarded_a << ' ' << guarded_b
            << " init-count=" << guarded_init_count << '\n';
  std::cout << (emutls_ok ? "CLING_WINDOWS_EMUTLS_PASS"
                         : "CLING_WINDOWS_EMUTLS_FAIL") << '\n';
}
