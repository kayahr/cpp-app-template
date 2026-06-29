// SPDX-FileCopyrightText: 2026 Klaus Reimer <k@ailis.de>
// SPDX-License-Identifier: MIT

#include "app.hpp"

#include <gtest/gtest.h>

#include <sstream>

TEST(AppTest, prints_sum) {
    std::ostringstream output;
    std::ostringstream error_output;

    const int exit_code = app({ "cpp-app-template", "1", "2" }, output, error_output);

    EXPECT_EQ(0, exit_code);
    EXPECT_EQ("3\n", output.str());
    EXPECT_EQ("", error_output.str());
}
