#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "system.h"
#include "io.h"

// Địa chỉ thanh ghi trong Avalon-MM
#define REG_SIGN_A     0
#define REG_INT_A      1
#define REG_FRAC_A     2
#define REG_SIGN_B     3
#define REG_INT_B      4
#define REG_FRAC_B     5
#define REG_OPCODE     6
#define REG_START      7
#define REG_RESULT     8
#define REG_DONE       9

// Chuyển từ số thực IEEE-754 sang định dạng input module
void unpack_float(uint32_t f, uint8_t* sign, uint8_t* int_part, uint8_t* frac_part) {
    *sign = (f >> 31) & 0x1;
    *int_part = (f >> 23) & 0xFF;
    *frac_part = (f >> 15) & 0xFF; // chỉ lấy 8 bit đầu của mantissa
}

int main() {
    FILE* file = fopen("D:\SOCTH\FPU\testcase.txt", "r");  //Tùy vào vị trí file testcase
    if (!file) {
        printf("Không thể mở testcase.txt\n");
        return 1;
    }

    for (int tc = 1; tc <= 100; tc++) {
        char a_str[9], b_str[9], expect_str[9];
        int s;

        if (fscanf(file, "%8s %8s %d %8s", a_str, b_str, &s, expect_str) != 4) {
            printf("Lỗi đọc testcase tại dòng %d\n", tc);
            break;
        }

        uint32_t a = (uint32_t)strtoul(a_str, NULL, 16);
        uint32_t b = (uint32_t)strtoul(b_str, NULL, 16);
        uint32_t expect = (uint32_t)strtoul(expect_str, NULL, 16);

        // Tách thành phần cho a và b
        uint8_t sign_a, int_a, frac_a;
        uint8_t sign_b, int_b, frac_b;
        unpack_float(a, &sign_a, &int_a, &frac_a);
        unpack_float(b, &sign_b, &int_b, &frac_b);

        // Gửi dữ liệu vào Avalon-MM
        IOWR_32DIRECT(FPU_0_BASE, REG_SIGN_A * 4, sign_a);
        IOWR_32DIRECT(FPU_0_BASE, REG_INT_A * 4, int_a);
        IOWR_32DIRECT(FPU_0_BASE, REG_FRAC_A * 4, frac_a);
        IOWR_32DIRECT(FPU_0_BASE, REG_SIGN_B * 4, sign_b);
        IOWR_32DIRECT(FPU_0_BASE, REG_INT_B * 4, int_b);
        IOWR_32DIRECT(FPU_0_BASE, REG_FRAC_B * 4, frac_b);
        IOWR_32DIRECT(FPU_0_BASE, REG_OPCODE * 4, s);
        IOWR_32DIRECT(FPU_0_BASE, REG_START * 4, 1);

        while (IORD_32DIRECT(FPU_0_BASE, REG_DONE * 4) == 0);

        uint32_t result = IORD_32DIRECT(FPU_0_BASE, REG_RESULT * 4);

        // In kết quả
        printf("Testcase %d:\n", tc);
        printf("a = %08X => ", a);
        for (int i = 31; i >= 0; i--) printf("%d", (a >> i) & 1);
        printf("\nb = %08X => ", b);
        for (int i = 31; i >= 0; i--) printf("%d", (b >> i) & 1);
        printf("\nS = %02d\n", s);
        printf("result = ");
        for (int i = 31; i >= 0; i--) printf("%d", (result >> i) & 1);
        printf("\nexpect = ");
        for (int i = 31; i >= 0; i--) printf("%d", (expect >> i) & 1);

        if (result == expect)
            printf("\n----------PASS----------\n\n");
        else
            printf("\n==========FAIL==========\n\n");


    }

    fclose(file);
    return 0;
}
