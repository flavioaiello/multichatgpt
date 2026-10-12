#include <mach-o/dyld.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
int main(void) {
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) != 0) return 1;
    char *last = strrchr(path, '/');
    if (!last) return 1;
    *last = '\0';
    char script[PATH_MAX];
    int length = snprintf(script, sizeof(script), "%s/../Resources/launch-account2.sh", path);
    if (length < 0 || (size_t)length >= sizeof(script)) return 1;
    execl("/bin/zsh", "zsh", script, (char *)NULL);
    perror("Unable to start Account 2 launcher");
    return 1;
}
