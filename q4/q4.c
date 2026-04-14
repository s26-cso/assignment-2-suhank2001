#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <string.h>

int main() {
    char op[10];
    int a, b;

    // Loop to take inputs from command line
    while (scanf("%s %d %d", op, &a, &b) != EOF) {
        char lib_path[20];
        // Construct the library name: lib<op>.so
        snprintf(lib_path, sizeof(lib_path), "./lib%s.so", op);

        // 1. Open the shared library
        // RTLD_LAZY is fine here as we call it immediately
        void *handle = dlopen(lib_path, RTLD_LAZY);
        if (!handle) {
            // Silently skip or handle error if library doesn't exist
            continue;
        }

        // 2. Clear any existing error
        dlerror();

        // 3. Get the function pointer
        // The function name is the same as the operation name
        int (*operation_func)(int, int);
        operation_func = (int (*)(int, int))dlsym(handle, op);

        char *error = dlerror();
        if (error == NULL) {
            // 4. Execute the function and print result
            int result = operation_func(a, b);
            printf("%d\n", result);
            fflush(stdout);
        }

        // 5. Close the library to stay under the 2GB memory limit
        // This is vital because each lib is 1.5GB
        dlclose(handle);
    }

    return 0;
}
