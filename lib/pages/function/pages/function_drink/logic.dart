import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:schedule/common/api/drink/drink_api.dart';
import 'package:schedule/common/utils/logger_utils.dart';
import 'package:schedule/global_logic.dart';
import 'package:schedule/pages/login/view.dart';

import '../../../../generated/l10n.dart';
import '../../../app_main/logic.dart';
import '../../function_route_config.dart';
import 'state.dart';

class FunctionDrinkLogic extends GetxController {
  final FunctionDrinkState state = FunctionDrinkState();
  final globalState = Get.find<GlobalLogic>().state;
  final globalLogic = Get.find<GlobalLogic>();

  final drinkApi = DrinkApi();

  Future<void> init() async {
    checkLogin();
    getDeviceList();
  }

  /// 判断是否需要跳转登录
  void checkLogin() {
    if (!globalState.hui798UserInfo["hui798IsLogin"]) {
      final appMainLogic = Get.find<AppMainLogic>().state;

      if (appMainLogic.orientation.value) {
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.toNamed(FunctionRouteConfig.login,
              id: 2, arguments: {"type": LoginPageType.hui798});
        });
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.offNamed(FunctionRouteConfig.login,
              id: 3, arguments: {"type": LoginPageType.hui798});
        });
      }
    }
  }

  /// 获取喝水设备列表
  void getDeviceList() {
    // 获取设备列表
    drinkApi.deviceList().then((value) {
      if (value[0]["name"] == "Account failure") {
        globalLogic.setHui798UserInfo("hui798IsLogin", false);
        state.deviceList.clear();
        update();
        checkLogin();
      } else {
        state.deviceList.value = value;
        update();
      }
    });
  }

  /// 格式化设备名称
  String formatDeviceName(String name) {
    if (name.contains("栋")) {
      return name.replaceAll("栋", "-");
    } else {
      return name;
    }
  }

  /// 开始喝水
  void startDrink(int index) {
    drinkApi.startDrink(id: state.deviceList[index]["id"]).then((value) {
      if (value) {
        state.choiceDevice.value = index;
        // 使用count增加容错
        int count = 0;
        Get.snackbar(
          S.current.login_statue,
          S.current.function_drink_switch_start_success,
          backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
          margin: EdgeInsets.only(
            top: 30.w,
            left: 50.w,
            right: 50.w,
          ),
        );
        state.deviceStatusTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) async {
              bool isAvailable = await drinkApi.isAvailableDevice(
                  id: state.deviceList[index]["id"]);
              // logger.i(isAvailable);
              if (isAvailable && count > 3) {
                state.choiceDevice.value = -1;
                state.deviceStatusTimer?.cancel();
                update();
              } else if (isAvailable) {
                count++;
              }
            });
      } else {
        Get.snackbar(
          S.current.login_statue,
          S.current.function_drink_switch_start_fail,
          backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
          margin: EdgeInsets.only(
            top: 30.w,
            left: 50.w,
            right: 50.w,
          ),
        );
      }
      update();
    });
  }

  /// 结束喝水
  void endDrink(int index) {
    drinkApi.endDrink(id: state.deviceList[index]["id"]).then((value) {
      if (value) {
        state.choiceDevice.value = -1;
        state.deviceStatusTimer?.cancel();
        Get.snackbar(
          S.current.login_statue,
          S.current.function_drink_switch_end_success,
          backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
          margin: EdgeInsets.only(
            top: 30.w,
            left: 50.w,
            right: 50.w,
          ),
        );
      } else {
        Get.snackbar(
          S.current.login_statue,
          S.current.function_drink_switch_end_fail,
          backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
          margin: EdgeInsets.only(
            top: 30.w,
            left: 50.w,
            right: 50.w,
          ),
        );
      }
      update();
    });
  }
}