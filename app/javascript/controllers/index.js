// Import and register all your controllers
import { application } from "./application"

// 個別にコントローラーをインポート
import LiffController from "./liff_controller"
import ModalController from "./modal_controller"
import SortableController from "./sortable_controller"
import ToastController from "./toast_controller"
import ScrollToActiveController from "./scroll_to_active_controller"
import TestController from "./test_controller"

application.register("liff", LiffController)
application.register("modal", ModalController)
application.register("sortable", SortableController)
application.register("toast", ToastController)
application.register("scroll-to-active", ScrollToActiveController)
application.register("test", TestController)
