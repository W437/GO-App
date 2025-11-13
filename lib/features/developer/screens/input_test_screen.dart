/// Test screen for Modern Input Field Widget
/// Showcases all input types and features

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/forms/modern_input_field_widget.dart';
import 'package:godelivery_user/common/widgets/shared/text/validate_check.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class InputTestScreen extends StatefulWidget {
  const InputTestScreen({super.key});

  @override
  State<InputTestScreen> createState() => _InputTestScreenState();
}

class _InputTestScreenState extends State<InputTestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();

  // Focus nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  // Dropdown values
  String? _selectedCountry;
  String? _selectedCity;
  int? _selectedPriority;

  String? _countryDialCode;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _numberController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'Modern Input Test'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Text Inputs'),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Regular text input
              ModernInputFieldWidget(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                controller: _nameController,
                focusNode: _nameFocus,
                nextFocus: _emailFocus,
                required: true,
                prefixIcon: Icons.person,
                validator: (value) => ValidateCheck.validateEmptyText(value, "name_required".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Email input
              ModernInputFieldWidget(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                controller: _emailController,
                focusNode: _emailFocus,
                nextFocus: _passwordFocus,
                inputType: TextInputType.emailAddress,
                required: true,
                prefixIcon: Icons.email,
                validator: (value) => ValidateCheck.validateEmail(value),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Password input
              ModernInputFieldWidget(
                labelText: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                focusNode: _passwordFocus,
                nextFocus: _phoneFocus,
                isPassword: true,
                required: true,
                prefixIcon: Icons.lock,
                validator: (value) => ValidateCheck.validatePassword(value, "password_required".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Phone input with country picker
              ModernInputFieldWidget(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                controller: _phoneController,
                focusNode: _phoneFocus,
                inputType: TextInputType.phone,
                isPhone: true,
                countryDialCode: _countryDialCode ?? '+972',
                onCountryChanged: (CountryCode code) {
                  setState(() {
                    _countryDialCode = code.dialCode;
                  });
                },
                required: true,
                validator: (value) => ValidateCheck.validateEmptyText(value, "phone_required".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Number input
              ModernInputFieldWidget(
                labelText: 'Age',
                hintText: 'Enter your age',
                controller: _numberController,
                isNumber: true,
                prefixIcon: Icons.calendar_today,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Amount input
              ModernInputFieldWidget(
                labelText: 'Amount',
                hintText: 'Enter amount',
                controller: _amountController,
                isAmount: true,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _buildSectionTitle('Side by Side Fields'),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Two fields in a row
              Row(
                children: [
                  Expanded(
                    child: ModernInputFieldWidget(
                      labelText: 'First Name',
                      hintText: 'Enter first name',
                      controller: TextEditingController(),
                      prefixIcon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: ModernInputFieldWidget(
                      labelText: 'Last Name',
                      hintText: 'Enter last name',
                      controller: TextEditingController(),
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _buildSectionTitle('Dropdown Inputs'),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Simple dropdown
              ModernInputFieldWidget<String>(
                labelText: 'Country',
                hintText: 'Select your country',
                inputFieldType: ModernInputType.dropdown,
                selectedValue: _selectedCountry,
                required: true,
                dropdownItems: [
                  DropdownItem(
                    value: 'israel',
                    label: 'Israel',
                    icon: const Text('🇮🇱', style: TextStyle(fontSize: 20)),
                  ),
                  DropdownItem(
                    value: 'usa',
                    label: 'United States',
                    icon: const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                  ),
                  DropdownItem(
                    value: 'uk',
                    label: 'United Kingdom',
                    icon: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                  ),
                  DropdownItem(
                    value: 'canada',
                    label: 'Canada',
                    icon: const Text('🇨🇦', style: TextStyle(fontSize: 20)),
                  ),
                ],
                onDropdownChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _selectedCity = null; // Reset city when country changes
                  });
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Searchable dropdown
              ModernInputFieldWidget<String>(
                labelText: 'City',
                hintText: 'Search and select city',
                inputFieldType: ModernInputType.searchableDropdown,
                selectedValue: _selectedCity,
                searchable: true,
                dropdownItems: [
                  DropdownItem(value: 'jerusalem', label: 'Jerusalem'),
                  DropdownItem(value: 'tel_aviv', label: 'Tel Aviv'),
                  DropdownItem(value: 'haifa', label: 'Haifa'),
                  DropdownItem(value: 'beer_sheva', label: 'Beer Sheva'),
                  DropdownItem(value: 'netanya', label: 'Netanya'),
                  DropdownItem(value: 'ashdod', label: 'Ashdod'),
                  DropdownItem(value: 'rishon', label: 'Rishon LeZion'),
                  DropdownItem(value: 'petah_tikva', label: 'Petah Tikva'),
                  DropdownItem(value: 'holon', label: 'Holon'),
                  DropdownItem(value: 'ramat_gan', label: 'Ramat Gan'),
                ],
                onDropdownChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Dropdown with icons
              ModernInputFieldWidget<int>(
                labelText: 'Priority Level',
                hintText: 'Select priority',
                inputFieldType: ModernInputType.dropdown,
                selectedValue: _selectedPriority,
                prefixIcon: Icons.flag,
                dropdownItems: [
                  DropdownItem(
                    value: 1,
                    label: 'High',
                    icon: Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                  ),
                  DropdownItem(
                    value: 2,
                    label: 'Medium',
                    icon: Icon(Icons.remove, color: Colors.orange, size: 20),
                  ),
                  DropdownItem(
                    value: 3,
                    label: 'Low',
                    icon: Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                  ),
                ],
                onDropdownChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _buildSectionTitle('Disabled State'),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Disabled text input
              ModernInputFieldWidget(
                labelText: 'Disabled Field',
                hintText: 'This field is disabled',
                controller: TextEditingController(text: 'Cannot edit this'),
                enabled: false,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _buildSectionTitle('Multi-line Input'),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Multi-line text area
              ModernInputFieldWidget(
                labelText: 'Comments',
                hintText: 'Enter your comments here',
                controller: TextEditingController(),
                maxLines: 4,
                prefixIcon: Icons.comment,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Submit button
              CustomButtonWidget(
                buttonText: 'Validate Form',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Get.snackbar(
                      'Success',
                      'All fields are valid!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Please fill all required fields correctly',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: robotoBold.copyWith(
        fontSize: Dimensions.fontSizeExtraLarge,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}
