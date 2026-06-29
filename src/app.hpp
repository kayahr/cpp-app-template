// SPDX-FileCopyrightText: 2026 Klaus Reimer <k@ailis.de>
// SPDX-License-Identifier: MIT

#pragma once

#include <iosfwd>
#include <vector>

int app(std::vector<const char*> arguments, std::ostream& output, std::ostream& error_output);
