﻿#include "absl/log/globals.h"
#include "absl/log/initialize.h"
#include "absl/log/log.h"
#include "api.hpp"
#include "impl/impl.hpp"

int main() {
    absl::InitializeLog();
    absl::SetStderrThreshold(absl::LogSeverity::kInfo);
    LOG(INFO) << "Hello, Remote World!"
              << "\n"
              << api::info::version_api() << '\n'
              << (api::info::is_debug() ? "Is" : "Is not") << " debug distribution" << '\n'
              << api::geo::PrintDrawableToString(api::geo::CreateRectangleAsDrawable(100, 100)) << '\n';
    return 0;
}