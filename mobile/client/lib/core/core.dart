// Barrel export pour toutes les constantes de l'application
// Usage: import 'package:dr_pharma_user/core/core.dart';

// Constants
export 'constants/api_constants.dart';
export 'constants/app_colors.dart';
export 'constants/app_constants.dart';
export 'constants/app_dimensions.dart';
export 'constants/app_text_styles.dart';
export 'constants/app_theme.dart';

// Extensions
export 'extensions/extensions.dart';

// Widgets
export 'widgets/common_widgets.dart';
export 'widgets/async_value_widget.dart';

// Errors
export 'errors/failures.dart';
export 'errors/exceptions.dart' hide NetworkException, ValidationException;
export 'errors/error_handler.dart';

// Utils
export 'utils/validators.dart';
export 'utils/page_transitions.dart';
export 'utils/responsive_utils.dart';

// Services
export 'services/app_logger.dart';
export 'services/secure_storage_service.dart';

// Validators
export 'validators/form_validators.dart';

// Router
export 'router/app_router.dart';
