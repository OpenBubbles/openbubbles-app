// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AttachmentType {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List field0) inline,
    required TResult Function(MMCSFile field0) mmcs,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List field0)? inline,
    TResult? Function(MMCSFile field0)? mmcs,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List field0)? inline,
    TResult Function(MMCSFile field0)? mmcs,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AttachmentType_Inline value) inline,
    required TResult Function(AttachmentType_MMCS value) mmcs,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AttachmentType_Inline value)? inline,
    TResult? Function(AttachmentType_MMCS value)? mmcs,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AttachmentType_Inline value)? inline,
    TResult Function(AttachmentType_MMCS value)? mmcs,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttachmentTypeCopyWith<$Res> {
  factory $AttachmentTypeCopyWith(
          AttachmentType value, $Res Function(AttachmentType) then) =
      _$AttachmentTypeCopyWithImpl<$Res, AttachmentType>;
}

/// @nodoc
class _$AttachmentTypeCopyWithImpl<$Res, $Val extends AttachmentType>
    implements $AttachmentTypeCopyWith<$Res> {
  _$AttachmentTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AttachmentType_InlineImplCopyWith<$Res> {
  factory _$$AttachmentType_InlineImplCopyWith(
          _$AttachmentType_InlineImpl value,
          $Res Function(_$AttachmentType_InlineImpl) then) =
      __$$AttachmentType_InlineImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Uint8List field0});
}

/// @nodoc
class __$$AttachmentType_InlineImplCopyWithImpl<$Res>
    extends _$AttachmentTypeCopyWithImpl<$Res, _$AttachmentType_InlineImpl>
    implements _$$AttachmentType_InlineImplCopyWith<$Res> {
  __$$AttachmentType_InlineImplCopyWithImpl(_$AttachmentType_InlineImpl _value,
      $Res Function(_$AttachmentType_InlineImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$AttachmentType_InlineImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc

class _$AttachmentType_InlineImpl extends AttachmentType_Inline {
  const _$AttachmentType_InlineImpl(this.field0) : super._();

  @override
  final Uint8List field0;

  @override
  String toString() {
    return 'AttachmentType.inline(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentType_InlineImpl &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentType_InlineImplCopyWith<_$AttachmentType_InlineImpl>
      get copyWith => __$$AttachmentType_InlineImplCopyWithImpl<
          _$AttachmentType_InlineImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List field0) inline,
    required TResult Function(MMCSFile field0) mmcs,
  }) {
    return inline(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List field0)? inline,
    TResult? Function(MMCSFile field0)? mmcs,
  }) {
    return inline?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List field0)? inline,
    TResult Function(MMCSFile field0)? mmcs,
    required TResult orElse(),
  }) {
    if (inline != null) {
      return inline(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AttachmentType_Inline value) inline,
    required TResult Function(AttachmentType_MMCS value) mmcs,
  }) {
    return inline(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AttachmentType_Inline value)? inline,
    TResult? Function(AttachmentType_MMCS value)? mmcs,
  }) {
    return inline?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AttachmentType_Inline value)? inline,
    TResult Function(AttachmentType_MMCS value)? mmcs,
    required TResult orElse(),
  }) {
    if (inline != null) {
      return inline(this);
    }
    return orElse();
  }
}

abstract class AttachmentType_Inline extends AttachmentType {
  const factory AttachmentType_Inline(final Uint8List field0) =
      _$AttachmentType_InlineImpl;
  const AttachmentType_Inline._() : super._();

  @override
  Uint8List get field0;

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttachmentType_InlineImplCopyWith<_$AttachmentType_InlineImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AttachmentType_MMCSImplCopyWith<$Res> {
  factory _$$AttachmentType_MMCSImplCopyWith(_$AttachmentType_MMCSImpl value,
          $Res Function(_$AttachmentType_MMCSImpl) then) =
      __$$AttachmentType_MMCSImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MMCSFile field0});
}

/// @nodoc
class __$$AttachmentType_MMCSImplCopyWithImpl<$Res>
    extends _$AttachmentTypeCopyWithImpl<$Res, _$AttachmentType_MMCSImpl>
    implements _$$AttachmentType_MMCSImplCopyWith<$Res> {
  __$$AttachmentType_MMCSImplCopyWithImpl(_$AttachmentType_MMCSImpl _value,
      $Res Function(_$AttachmentType_MMCSImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$AttachmentType_MMCSImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MMCSFile,
    ));
  }
}

/// @nodoc

class _$AttachmentType_MMCSImpl extends AttachmentType_MMCS {
  const _$AttachmentType_MMCSImpl(this.field0) : super._();

  @override
  final MMCSFile field0;

  @override
  String toString() {
    return 'AttachmentType.mmcs(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentType_MMCSImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentType_MMCSImplCopyWith<_$AttachmentType_MMCSImpl> get copyWith =>
      __$$AttachmentType_MMCSImplCopyWithImpl<_$AttachmentType_MMCSImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List field0) inline,
    required TResult Function(MMCSFile field0) mmcs,
  }) {
    return mmcs(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List field0)? inline,
    TResult? Function(MMCSFile field0)? mmcs,
  }) {
    return mmcs?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List field0)? inline,
    TResult Function(MMCSFile field0)? mmcs,
    required TResult orElse(),
  }) {
    if (mmcs != null) {
      return mmcs(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AttachmentType_Inline value) inline,
    required TResult Function(AttachmentType_MMCS value) mmcs,
  }) {
    return mmcs(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AttachmentType_Inline value)? inline,
    TResult? Function(AttachmentType_MMCS value)? mmcs,
  }) {
    return mmcs?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AttachmentType_Inline value)? inline,
    TResult Function(AttachmentType_MMCS value)? mmcs,
    required TResult orElse(),
  }) {
    if (mmcs != null) {
      return mmcs(this);
    }
    return orElse();
  }
}

abstract class AttachmentType_MMCS extends AttachmentType {
  const factory AttachmentType_MMCS(final MMCSFile field0) =
      _$AttachmentType_MMCSImpl;
  const AttachmentType_MMCS._() : super._();

  @override
  MMCSFile get field0;

  /// Create a copy of AttachmentType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttachmentType_MMCSImplCopyWith<_$AttachmentType_MMCSImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BalloonLayout {
  String get imageSubtitle => throw _privateConstructorUsedError;
  String get imageTitle => throw _privateConstructorUsedError;
  String get caption => throw _privateConstructorUsedError;
  String get secondarySubcaption => throw _privateConstructorUsedError;
  String get tertiarySubcaption => throw _privateConstructorUsedError;
  String get subcaption => throw _privateConstructorUsedError;
  NSDictionaryClass get class_ => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String imageSubtitle,
            String imageTitle,
            String caption,
            String secondarySubcaption,
            String tertiarySubcaption,
            String subcaption,
            NSDictionaryClass class_)
        templateLayout,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String imageSubtitle,
            String imageTitle,
            String caption,
            String secondarySubcaption,
            String tertiarySubcaption,
            String subcaption,
            NSDictionaryClass class_)?
        templateLayout,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String imageSubtitle,
            String imageTitle,
            String caption,
            String secondarySubcaption,
            String tertiarySubcaption,
            String subcaption,
            NSDictionaryClass class_)?
        templateLayout,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BalloonLayout_TemplateLayout value)
        templateLayout,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BalloonLayout_TemplateLayout value)? templateLayout,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BalloonLayout_TemplateLayout value)? templateLayout,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of BalloonLayout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BalloonLayoutCopyWith<BalloonLayout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BalloonLayoutCopyWith<$Res> {
  factory $BalloonLayoutCopyWith(
          BalloonLayout value, $Res Function(BalloonLayout) then) =
      _$BalloonLayoutCopyWithImpl<$Res, BalloonLayout>;
  @useResult
  $Res call(
      {String imageSubtitle,
      String imageTitle,
      String caption,
      String secondarySubcaption,
      String tertiarySubcaption,
      String subcaption,
      NSDictionaryClass class_});
}

/// @nodoc
class _$BalloonLayoutCopyWithImpl<$Res, $Val extends BalloonLayout>
    implements $BalloonLayoutCopyWith<$Res> {
  _$BalloonLayoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BalloonLayout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageSubtitle = null,
    Object? imageTitle = null,
    Object? caption = null,
    Object? secondarySubcaption = null,
    Object? tertiarySubcaption = null,
    Object? subcaption = null,
    Object? class_ = null,
  }) {
    return _then(_value.copyWith(
      imageSubtitle: null == imageSubtitle
          ? _value.imageSubtitle
          : imageSubtitle // ignore: cast_nullable_to_non_nullable
              as String,
      imageTitle: null == imageTitle
          ? _value.imageTitle
          : imageTitle // ignore: cast_nullable_to_non_nullable
              as String,
      caption: null == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String,
      secondarySubcaption: null == secondarySubcaption
          ? _value.secondarySubcaption
          : secondarySubcaption // ignore: cast_nullable_to_non_nullable
              as String,
      tertiarySubcaption: null == tertiarySubcaption
          ? _value.tertiarySubcaption
          : tertiarySubcaption // ignore: cast_nullable_to_non_nullable
              as String,
      subcaption: null == subcaption
          ? _value.subcaption
          : subcaption // ignore: cast_nullable_to_non_nullable
              as String,
      class_: null == class_
          ? _value.class_
          : class_ // ignore: cast_nullable_to_non_nullable
              as NSDictionaryClass,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BalloonLayout_TemplateLayoutImplCopyWith<$Res>
    implements $BalloonLayoutCopyWith<$Res> {
  factory _$$BalloonLayout_TemplateLayoutImplCopyWith(
          _$BalloonLayout_TemplateLayoutImpl value,
          $Res Function(_$BalloonLayout_TemplateLayoutImpl) then) =
      __$$BalloonLayout_TemplateLayoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String imageSubtitle,
      String imageTitle,
      String caption,
      String secondarySubcaption,
      String tertiarySubcaption,
      String subcaption,
      NSDictionaryClass class_});
}

/// @nodoc
class __$$BalloonLayout_TemplateLayoutImplCopyWithImpl<$Res>
    extends _$BalloonLayoutCopyWithImpl<$Res,
        _$BalloonLayout_TemplateLayoutImpl>
    implements _$$BalloonLayout_TemplateLayoutImplCopyWith<$Res> {
  __$$BalloonLayout_TemplateLayoutImplCopyWithImpl(
      _$BalloonLayout_TemplateLayoutImpl _value,
      $Res Function(_$BalloonLayout_TemplateLayoutImpl) _then)
      : super(_value, _then);

  /// Create a copy of BalloonLayout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageSubtitle = null,
    Object? imageTitle = null,
    Object? caption = null,
    Object? secondarySubcaption = null,
    Object? tertiarySubcaption = null,
    Object? subcaption = null,
    Object? class_ = null,
  }) {
    return _then(_$BalloonLayout_TemplateLayoutImpl(
      imageSubtitle: null == imageSubtitle
          ? _value.imageSubtitle
          : imageSubtitle // ignore: cast_nullable_to_non_nullable
              as String,
      imageTitle: null == imageTitle
          ? _value.imageTitle
          : imageTitle // ignore: cast_nullable_to_non_nullable
              as String,
      caption: null == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String,
      secondarySubcaption: null == secondarySubcaption
          ? _value.secondarySubcaption
          : secondarySubcaption // ignore: cast_nullable_to_non_nullable
              as String,
      tertiarySubcaption: null == tertiarySubcaption
          ? _value.tertiarySubcaption
          : tertiarySubcaption // ignore: cast_nullable_to_non_nullable
              as String,
      subcaption: null == subcaption
          ? _value.subcaption
          : subcaption // ignore: cast_nullable_to_non_nullable
              as String,
      class_: null == class_
          ? _value.class_
          : class_ // ignore: cast_nullable_to_non_nullable
              as NSDictionaryClass,
    ));
  }
}

/// @nodoc

class _$BalloonLayout_TemplateLayoutImpl extends BalloonLayout_TemplateLayout {
  const _$BalloonLayout_TemplateLayoutImpl(
      {required this.imageSubtitle,
      required this.imageTitle,
      required this.caption,
      required this.secondarySubcaption,
      required this.tertiarySubcaption,
      required this.subcaption,
      required this.class_})
      : super._();

  @override
  final String imageSubtitle;
  @override
  final String imageTitle;
  @override
  final String caption;
  @override
  final String secondarySubcaption;
  @override
  final String tertiarySubcaption;
  @override
  final String subcaption;
  @override
  final NSDictionaryClass class_;

  @override
  String toString() {
    return 'BalloonLayout.templateLayout(imageSubtitle: $imageSubtitle, imageTitle: $imageTitle, caption: $caption, secondarySubcaption: $secondarySubcaption, tertiarySubcaption: $tertiarySubcaption, subcaption: $subcaption, class_: $class_)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BalloonLayout_TemplateLayoutImpl &&
            (identical(other.imageSubtitle, imageSubtitle) ||
                other.imageSubtitle == imageSubtitle) &&
            (identical(other.imageTitle, imageTitle) ||
                other.imageTitle == imageTitle) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.secondarySubcaption, secondarySubcaption) ||
                other.secondarySubcaption == secondarySubcaption) &&
            (identical(other.tertiarySubcaption, tertiarySubcaption) ||
                other.tertiarySubcaption == tertiarySubcaption) &&
            (identical(other.subcaption, subcaption) ||
                other.subcaption == subcaption) &&
            (identical(other.class_, class_) || other.class_ == class_));
  }

  @override
  int get hashCode => Object.hash(runtimeType, imageSubtitle, imageTitle,
      caption, secondarySubcaption, tertiarySubcaption, subcaption, class_);

  /// Create a copy of BalloonLayout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BalloonLayout_TemplateLayoutImplCopyWith<
          _$BalloonLayout_TemplateLayoutImpl>
      get copyWith => __$$BalloonLayout_TemplateLayoutImplCopyWithImpl<
          _$BalloonLayout_TemplateLayoutImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String imageSubtitle,
            String imageTitle,
            String caption,
            String secondarySubcaption,
            String tertiarySubcaption,
            String subcaption,
            NSDictionaryClass class_)
        templateLayout,
  }) {
    return templateLayout(imageSubtitle, imageTitle, caption,
        secondarySubcaption, tertiarySubcaption, subcaption, class_);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String imageSubtitle,
            String imageTitle,
            String caption,
            String secondarySubcaption,
            String tertiarySubcaption,
            String subcaption,
            NSDictionaryClass class_)?
        templateLayout,
  }) {
    return templateLayout?.call(imageSubtitle, imageTitle, caption,
        secondarySubcaption, tertiarySubcaption, subcaption, class_);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String imageSubtitle,
            String imageTitle,
            String caption,
            String secondarySubcaption,
            String tertiarySubcaption,
            String subcaption,
            NSDictionaryClass class_)?
        templateLayout,
    required TResult orElse(),
  }) {
    if (templateLayout != null) {
      return templateLayout(imageSubtitle, imageTitle, caption,
          secondarySubcaption, tertiarySubcaption, subcaption, class_);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BalloonLayout_TemplateLayout value)
        templateLayout,
  }) {
    return templateLayout(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BalloonLayout_TemplateLayout value)? templateLayout,
  }) {
    return templateLayout?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BalloonLayout_TemplateLayout value)? templateLayout,
    required TResult orElse(),
  }) {
    if (templateLayout != null) {
      return templateLayout(this);
    }
    return orElse();
  }
}

abstract class BalloonLayout_TemplateLayout extends BalloonLayout {
  const factory BalloonLayout_TemplateLayout(
          {required final String imageSubtitle,
          required final String imageTitle,
          required final String caption,
          required final String secondarySubcaption,
          required final String tertiarySubcaption,
          required final String subcaption,
          required final NSDictionaryClass class_}) =
      _$BalloonLayout_TemplateLayoutImpl;
  const BalloonLayout_TemplateLayout._() : super._();

  @override
  String get imageSubtitle;
  @override
  String get imageTitle;
  @override
  String get caption;
  @override
  String get secondarySubcaption;
  @override
  String get tertiarySubcaption;
  @override
  String get subcaption;
  @override
  NSDictionaryClass get class_;

  /// Create a copy of BalloonLayout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BalloonLayout_TemplateLayoutImplCopyWith<
          _$BalloonLayout_TemplateLayoutImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DeleteTarget {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OperatedChat field0) chat,
    required TResult Function(List<String> field0) messages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OperatedChat field0)? chat,
    TResult? Function(List<String> field0)? messages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OperatedChat field0)? chat,
    TResult Function(List<String> field0)? messages,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeleteTarget_Chat value) chat,
    required TResult Function(DeleteTarget_Messages value) messages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeleteTarget_Chat value)? chat,
    TResult? Function(DeleteTarget_Messages value)? messages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeleteTarget_Chat value)? chat,
    TResult Function(DeleteTarget_Messages value)? messages,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeleteTargetCopyWith<$Res> {
  factory $DeleteTargetCopyWith(
          DeleteTarget value, $Res Function(DeleteTarget) then) =
      _$DeleteTargetCopyWithImpl<$Res, DeleteTarget>;
}

/// @nodoc
class _$DeleteTargetCopyWithImpl<$Res, $Val extends DeleteTarget>
    implements $DeleteTargetCopyWith<$Res> {
  _$DeleteTargetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DeleteTarget_ChatImplCopyWith<$Res> {
  factory _$$DeleteTarget_ChatImplCopyWith(_$DeleteTarget_ChatImpl value,
          $Res Function(_$DeleteTarget_ChatImpl) then) =
      __$$DeleteTarget_ChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({OperatedChat field0});
}

/// @nodoc
class __$$DeleteTarget_ChatImplCopyWithImpl<$Res>
    extends _$DeleteTargetCopyWithImpl<$Res, _$DeleteTarget_ChatImpl>
    implements _$$DeleteTarget_ChatImplCopyWith<$Res> {
  __$$DeleteTarget_ChatImplCopyWithImpl(_$DeleteTarget_ChatImpl _value,
      $Res Function(_$DeleteTarget_ChatImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$DeleteTarget_ChatImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as OperatedChat,
    ));
  }
}

/// @nodoc

class _$DeleteTarget_ChatImpl extends DeleteTarget_Chat {
  const _$DeleteTarget_ChatImpl(this.field0) : super._();

  @override
  final OperatedChat field0;

  @override
  String toString() {
    return 'DeleteTarget.chat(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteTarget_ChatImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteTarget_ChatImplCopyWith<_$DeleteTarget_ChatImpl> get copyWith =>
      __$$DeleteTarget_ChatImplCopyWithImpl<_$DeleteTarget_ChatImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OperatedChat field0) chat,
    required TResult Function(List<String> field0) messages,
  }) {
    return chat(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OperatedChat field0)? chat,
    TResult? Function(List<String> field0)? messages,
  }) {
    return chat?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OperatedChat field0)? chat,
    TResult Function(List<String> field0)? messages,
    required TResult orElse(),
  }) {
    if (chat != null) {
      return chat(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeleteTarget_Chat value) chat,
    required TResult Function(DeleteTarget_Messages value) messages,
  }) {
    return chat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeleteTarget_Chat value)? chat,
    TResult? Function(DeleteTarget_Messages value)? messages,
  }) {
    return chat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeleteTarget_Chat value)? chat,
    TResult Function(DeleteTarget_Messages value)? messages,
    required TResult orElse(),
  }) {
    if (chat != null) {
      return chat(this);
    }
    return orElse();
  }
}

abstract class DeleteTarget_Chat extends DeleteTarget {
  const factory DeleteTarget_Chat(final OperatedChat field0) =
      _$DeleteTarget_ChatImpl;
  const DeleteTarget_Chat._() : super._();

  @override
  OperatedChat get field0;

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeleteTarget_ChatImplCopyWith<_$DeleteTarget_ChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeleteTarget_MessagesImplCopyWith<$Res> {
  factory _$$DeleteTarget_MessagesImplCopyWith(
          _$DeleteTarget_MessagesImpl value,
          $Res Function(_$DeleteTarget_MessagesImpl) then) =
      __$$DeleteTarget_MessagesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> field0});
}

/// @nodoc
class __$$DeleteTarget_MessagesImplCopyWithImpl<$Res>
    extends _$DeleteTargetCopyWithImpl<$Res, _$DeleteTarget_MessagesImpl>
    implements _$$DeleteTarget_MessagesImplCopyWith<$Res> {
  __$$DeleteTarget_MessagesImplCopyWithImpl(_$DeleteTarget_MessagesImpl _value,
      $Res Function(_$DeleteTarget_MessagesImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$DeleteTarget_MessagesImpl(
      null == field0
          ? _value._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$DeleteTarget_MessagesImpl extends DeleteTarget_Messages {
  const _$DeleteTarget_MessagesImpl(final List<String> field0)
      : _field0 = field0,
        super._();

  final List<String> _field0;
  @override
  List<String> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  @override
  String toString() {
    return 'DeleteTarget.messages(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteTarget_MessagesImpl &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteTarget_MessagesImplCopyWith<_$DeleteTarget_MessagesImpl>
      get copyWith => __$$DeleteTarget_MessagesImplCopyWithImpl<
          _$DeleteTarget_MessagesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OperatedChat field0) chat,
    required TResult Function(List<String> field0) messages,
  }) {
    return messages(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OperatedChat field0)? chat,
    TResult? Function(List<String> field0)? messages,
  }) {
    return messages?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OperatedChat field0)? chat,
    TResult Function(List<String> field0)? messages,
    required TResult orElse(),
  }) {
    if (messages != null) {
      return messages(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeleteTarget_Chat value) chat,
    required TResult Function(DeleteTarget_Messages value) messages,
  }) {
    return messages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeleteTarget_Chat value)? chat,
    TResult? Function(DeleteTarget_Messages value)? messages,
  }) {
    return messages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeleteTarget_Chat value)? chat,
    TResult Function(DeleteTarget_Messages value)? messages,
    required TResult orElse(),
  }) {
    if (messages != null) {
      return messages(this);
    }
    return orElse();
  }
}

abstract class DeleteTarget_Messages extends DeleteTarget {
  const factory DeleteTarget_Messages(final List<String> field0) =
      _$DeleteTarget_MessagesImpl;
  const DeleteTarget_Messages._() : super._();

  @override
  List<String> get field0;

  /// Create a copy of DeleteTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeleteTarget_MessagesImplCopyWith<_$DeleteTarget_MessagesImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$LoginState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginStateCopyWith<$Res> {
  factory $LoginStateCopyWith(
          LoginState value, $Res Function(LoginState) then) =
      _$LoginStateCopyWithImpl<$Res, LoginState>;
}

/// @nodoc
class _$LoginStateCopyWithImpl<$Res, $Val extends LoginState>
    implements $LoginStateCopyWith<$Res> {
  _$LoginStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoginState_LoggedInImplCopyWith<$Res> {
  factory _$$LoginState_LoggedInImplCopyWith(_$LoginState_LoggedInImpl value,
          $Res Function(_$LoginState_LoggedInImpl) then) =
      __$$LoginState_LoggedInImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoginState_LoggedInImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res, _$LoginState_LoggedInImpl>
    implements _$$LoginState_LoggedInImplCopyWith<$Res> {
  __$$LoginState_LoggedInImplCopyWithImpl(_$LoginState_LoggedInImpl _value,
      $Res Function(_$LoginState_LoggedInImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoginState_LoggedInImpl extends LoginState_LoggedIn {
  const _$LoginState_LoggedInImpl() : super._();

  @override
  String toString() {
    return 'LoginState.loggedIn()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_LoggedInImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return loggedIn();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return loggedIn?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (loggedIn != null) {
      return loggedIn();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return loggedIn(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return loggedIn?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (loggedIn != null) {
      return loggedIn(this);
    }
    return orElse();
  }
}

abstract class LoginState_LoggedIn extends LoginState {
  const factory LoginState_LoggedIn() = _$LoginState_LoggedInImpl;
  const LoginState_LoggedIn._() : super._();
}

/// @nodoc
abstract class _$$LoginState_NeedsDevice2FAImplCopyWith<$Res> {
  factory _$$LoginState_NeedsDevice2FAImplCopyWith(
          _$LoginState_NeedsDevice2FAImpl value,
          $Res Function(_$LoginState_NeedsDevice2FAImpl) then) =
      __$$LoginState_NeedsDevice2FAImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoginState_NeedsDevice2FAImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res, _$LoginState_NeedsDevice2FAImpl>
    implements _$$LoginState_NeedsDevice2FAImplCopyWith<$Res> {
  __$$LoginState_NeedsDevice2FAImplCopyWithImpl(
      _$LoginState_NeedsDevice2FAImpl _value,
      $Res Function(_$LoginState_NeedsDevice2FAImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoginState_NeedsDevice2FAImpl extends LoginState_NeedsDevice2FA {
  const _$LoginState_NeedsDevice2FAImpl() : super._();

  @override
  String toString() {
    return 'LoginState.needsDevice2Fa()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_NeedsDevice2FAImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return needsDevice2Fa();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return needsDevice2Fa?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (needsDevice2Fa != null) {
      return needsDevice2Fa();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return needsDevice2Fa(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return needsDevice2Fa?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (needsDevice2Fa != null) {
      return needsDevice2Fa(this);
    }
    return orElse();
  }
}

abstract class LoginState_NeedsDevice2FA extends LoginState {
  const factory LoginState_NeedsDevice2FA() = _$LoginState_NeedsDevice2FAImpl;
  const LoginState_NeedsDevice2FA._() : super._();
}

/// @nodoc
abstract class _$$LoginState_Needs2FAVerificationImplCopyWith<$Res> {
  factory _$$LoginState_Needs2FAVerificationImplCopyWith(
          _$LoginState_Needs2FAVerificationImpl value,
          $Res Function(_$LoginState_Needs2FAVerificationImpl) then) =
      __$$LoginState_Needs2FAVerificationImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoginState_Needs2FAVerificationImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res,
        _$LoginState_Needs2FAVerificationImpl>
    implements _$$LoginState_Needs2FAVerificationImplCopyWith<$Res> {
  __$$LoginState_Needs2FAVerificationImplCopyWithImpl(
      _$LoginState_Needs2FAVerificationImpl _value,
      $Res Function(_$LoginState_Needs2FAVerificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoginState_Needs2FAVerificationImpl
    extends LoginState_Needs2FAVerification {
  const _$LoginState_Needs2FAVerificationImpl() : super._();

  @override
  String toString() {
    return 'LoginState.needs2FaVerification()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_Needs2FAVerificationImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return needs2FaVerification();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return needs2FaVerification?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (needs2FaVerification != null) {
      return needs2FaVerification();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return needs2FaVerification(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return needs2FaVerification?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (needs2FaVerification != null) {
      return needs2FaVerification(this);
    }
    return orElse();
  }
}

abstract class LoginState_Needs2FAVerification extends LoginState {
  const factory LoginState_Needs2FAVerification() =
      _$LoginState_Needs2FAVerificationImpl;
  const LoginState_Needs2FAVerification._() : super._();
}

/// @nodoc
abstract class _$$LoginState_NeedsSMS2FAImplCopyWith<$Res> {
  factory _$$LoginState_NeedsSMS2FAImplCopyWith(
          _$LoginState_NeedsSMS2FAImpl value,
          $Res Function(_$LoginState_NeedsSMS2FAImpl) then) =
      __$$LoginState_NeedsSMS2FAImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoginState_NeedsSMS2FAImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res, _$LoginState_NeedsSMS2FAImpl>
    implements _$$LoginState_NeedsSMS2FAImplCopyWith<$Res> {
  __$$LoginState_NeedsSMS2FAImplCopyWithImpl(
      _$LoginState_NeedsSMS2FAImpl _value,
      $Res Function(_$LoginState_NeedsSMS2FAImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoginState_NeedsSMS2FAImpl extends LoginState_NeedsSMS2FA {
  const _$LoginState_NeedsSMS2FAImpl() : super._();

  @override
  String toString() {
    return 'LoginState.needsSms2Fa()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_NeedsSMS2FAImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return needsSms2Fa();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return needsSms2Fa?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (needsSms2Fa != null) {
      return needsSms2Fa();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return needsSms2Fa(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return needsSms2Fa?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (needsSms2Fa != null) {
      return needsSms2Fa(this);
    }
    return orElse();
  }
}

abstract class LoginState_NeedsSMS2FA extends LoginState {
  const factory LoginState_NeedsSMS2FA() = _$LoginState_NeedsSMS2FAImpl;
  const LoginState_NeedsSMS2FA._() : super._();
}

/// @nodoc
abstract class _$$LoginState_NeedsSMS2FAVerificationImplCopyWith<$Res> {
  factory _$$LoginState_NeedsSMS2FAVerificationImplCopyWith(
          _$LoginState_NeedsSMS2FAVerificationImpl value,
          $Res Function(_$LoginState_NeedsSMS2FAVerificationImpl) then) =
      __$$LoginState_NeedsSMS2FAVerificationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({VerifyBody field0});
}

/// @nodoc
class __$$LoginState_NeedsSMS2FAVerificationImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res,
        _$LoginState_NeedsSMS2FAVerificationImpl>
    implements _$$LoginState_NeedsSMS2FAVerificationImplCopyWith<$Res> {
  __$$LoginState_NeedsSMS2FAVerificationImplCopyWithImpl(
      _$LoginState_NeedsSMS2FAVerificationImpl _value,
      $Res Function(_$LoginState_NeedsSMS2FAVerificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$LoginState_NeedsSMS2FAVerificationImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as VerifyBody,
    ));
  }
}

/// @nodoc

class _$LoginState_NeedsSMS2FAVerificationImpl
    extends LoginState_NeedsSMS2FAVerification {
  const _$LoginState_NeedsSMS2FAVerificationImpl(this.field0) : super._();

  @override
  final VerifyBody field0;

  @override
  String toString() {
    return 'LoginState.needsSms2FaVerification(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_NeedsSMS2FAVerificationImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginState_NeedsSMS2FAVerificationImplCopyWith<
          _$LoginState_NeedsSMS2FAVerificationImpl>
      get copyWith => __$$LoginState_NeedsSMS2FAVerificationImplCopyWithImpl<
          _$LoginState_NeedsSMS2FAVerificationImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return needsSms2FaVerification(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return needsSms2FaVerification?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (needsSms2FaVerification != null) {
      return needsSms2FaVerification(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return needsSms2FaVerification(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return needsSms2FaVerification?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (needsSms2FaVerification != null) {
      return needsSms2FaVerification(this);
    }
    return orElse();
  }
}

abstract class LoginState_NeedsSMS2FAVerification extends LoginState {
  const factory LoginState_NeedsSMS2FAVerification(final VerifyBody field0) =
      _$LoginState_NeedsSMS2FAVerificationImpl;
  const LoginState_NeedsSMS2FAVerification._() : super._();

  VerifyBody get field0;

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginState_NeedsSMS2FAVerificationImplCopyWith<
          _$LoginState_NeedsSMS2FAVerificationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoginState_NeedsExtraStepImplCopyWith<$Res> {
  factory _$$LoginState_NeedsExtraStepImplCopyWith(
          _$LoginState_NeedsExtraStepImpl value,
          $Res Function(_$LoginState_NeedsExtraStepImpl) then) =
      __$$LoginState_NeedsExtraStepImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$LoginState_NeedsExtraStepImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res, _$LoginState_NeedsExtraStepImpl>
    implements _$$LoginState_NeedsExtraStepImplCopyWith<$Res> {
  __$$LoginState_NeedsExtraStepImplCopyWithImpl(
      _$LoginState_NeedsExtraStepImpl _value,
      $Res Function(_$LoginState_NeedsExtraStepImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$LoginState_NeedsExtraStepImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LoginState_NeedsExtraStepImpl extends LoginState_NeedsExtraStep {
  const _$LoginState_NeedsExtraStepImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'LoginState.needsExtraStep(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_NeedsExtraStepImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginState_NeedsExtraStepImplCopyWith<_$LoginState_NeedsExtraStepImpl>
      get copyWith => __$$LoginState_NeedsExtraStepImplCopyWithImpl<
          _$LoginState_NeedsExtraStepImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return needsExtraStep(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return needsExtraStep?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (needsExtraStep != null) {
      return needsExtraStep(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return needsExtraStep(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return needsExtraStep?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (needsExtraStep != null) {
      return needsExtraStep(this);
    }
    return orElse();
  }
}

abstract class LoginState_NeedsExtraStep extends LoginState {
  const factory LoginState_NeedsExtraStep(final String field0) =
      _$LoginState_NeedsExtraStepImpl;
  const LoginState_NeedsExtraStep._() : super._();

  String get field0;

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginState_NeedsExtraStepImplCopyWith<_$LoginState_NeedsExtraStepImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoginState_NeedsLoginImplCopyWith<$Res> {
  factory _$$LoginState_NeedsLoginImplCopyWith(
          _$LoginState_NeedsLoginImpl value,
          $Res Function(_$LoginState_NeedsLoginImpl) then) =
      __$$LoginState_NeedsLoginImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoginState_NeedsLoginImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res, _$LoginState_NeedsLoginImpl>
    implements _$$LoginState_NeedsLoginImplCopyWith<$Res> {
  __$$LoginState_NeedsLoginImplCopyWithImpl(_$LoginState_NeedsLoginImpl _value,
      $Res Function(_$LoginState_NeedsLoginImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoginState_NeedsLoginImpl extends LoginState_NeedsLogin {
  const _$LoginState_NeedsLoginImpl() : super._();

  @override
  String toString() {
    return 'LoginState.needsLogin()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginState_NeedsLoginImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loggedIn,
    required TResult Function() needsDevice2Fa,
    required TResult Function() needs2FaVerification,
    required TResult Function() needsSms2Fa,
    required TResult Function(VerifyBody field0) needsSms2FaVerification,
    required TResult Function(String field0) needsExtraStep,
    required TResult Function() needsLogin,
  }) {
    return needsLogin();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loggedIn,
    TResult? Function()? needsDevice2Fa,
    TResult? Function()? needs2FaVerification,
    TResult? Function()? needsSms2Fa,
    TResult? Function(VerifyBody field0)? needsSms2FaVerification,
    TResult? Function(String field0)? needsExtraStep,
    TResult? Function()? needsLogin,
  }) {
    return needsLogin?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loggedIn,
    TResult Function()? needsDevice2Fa,
    TResult Function()? needs2FaVerification,
    TResult Function()? needsSms2Fa,
    TResult Function(VerifyBody field0)? needsSms2FaVerification,
    TResult Function(String field0)? needsExtraStep,
    TResult Function()? needsLogin,
    required TResult orElse(),
  }) {
    if (needsLogin != null) {
      return needsLogin();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginState_LoggedIn value) loggedIn,
    required TResult Function(LoginState_NeedsDevice2FA value) needsDevice2Fa,
    required TResult Function(LoginState_Needs2FAVerification value)
        needs2FaVerification,
    required TResult Function(LoginState_NeedsSMS2FA value) needsSms2Fa,
    required TResult Function(LoginState_NeedsSMS2FAVerification value)
        needsSms2FaVerification,
    required TResult Function(LoginState_NeedsExtraStep value) needsExtraStep,
    required TResult Function(LoginState_NeedsLogin value) needsLogin,
  }) {
    return needsLogin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginState_LoggedIn value)? loggedIn,
    TResult? Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult? Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult? Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult? Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult? Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult? Function(LoginState_NeedsLogin value)? needsLogin,
  }) {
    return needsLogin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginState_LoggedIn value)? loggedIn,
    TResult Function(LoginState_NeedsDevice2FA value)? needsDevice2Fa,
    TResult Function(LoginState_Needs2FAVerification value)?
        needs2FaVerification,
    TResult Function(LoginState_NeedsSMS2FA value)? needsSms2Fa,
    TResult Function(LoginState_NeedsSMS2FAVerification value)?
        needsSms2FaVerification,
    TResult Function(LoginState_NeedsExtraStep value)? needsExtraStep,
    TResult Function(LoginState_NeedsLogin value)? needsLogin,
    required TResult orElse(),
  }) {
    if (needsLogin != null) {
      return needsLogin(this);
    }
    return orElse();
  }
}

abstract class LoginState_NeedsLogin extends LoginState {
  const factory LoginState_NeedsLogin() = _$LoginState_NeedsLoginImpl;
  const LoginState_NeedsLogin._() : super._();
}

/// @nodoc
mixin _$Message {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Message_MessageImplCopyWith<$Res> {
  factory _$$Message_MessageImplCopyWith(_$Message_MessageImpl value,
          $Res Function(_$Message_MessageImpl) then) =
      __$$Message_MessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({NormalMessage field0});
}

/// @nodoc
class __$$Message_MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_MessageImpl>
    implements _$$Message_MessageImplCopyWith<$Res> {
  __$$Message_MessageImplCopyWithImpl(
      _$Message_MessageImpl _value, $Res Function(_$Message_MessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_MessageImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as NormalMessage,
    ));
  }
}

/// @nodoc

class _$Message_MessageImpl extends Message_Message {
  const _$Message_MessageImpl(this.field0) : super._();

  @override
  final NormalMessage field0;

  @override
  String toString() {
    return 'Message.message(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_MessageImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_MessageImplCopyWith<_$Message_MessageImpl> get copyWith =>
      __$$Message_MessageImplCopyWithImpl<_$Message_MessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return message(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return message?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (message != null) {
      return message(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return message(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return message?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (message != null) {
      return message(this);
    }
    return orElse();
  }
}

abstract class Message_Message extends Message {
  const factory Message_Message(final NormalMessage field0) =
      _$Message_MessageImpl;
  const Message_Message._() : super._();

  NormalMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_MessageImplCopyWith<_$Message_MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_RenameMessageImplCopyWith<$Res> {
  factory _$$Message_RenameMessageImplCopyWith(
          _$Message_RenameMessageImpl value,
          $Res Function(_$Message_RenameMessageImpl) then) =
      __$$Message_RenameMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({RenameMessage field0});
}

/// @nodoc
class __$$Message_RenameMessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_RenameMessageImpl>
    implements _$$Message_RenameMessageImplCopyWith<$Res> {
  __$$Message_RenameMessageImplCopyWithImpl(_$Message_RenameMessageImpl _value,
      $Res Function(_$Message_RenameMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_RenameMessageImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as RenameMessage,
    ));
  }
}

/// @nodoc

class _$Message_RenameMessageImpl extends Message_RenameMessage {
  const _$Message_RenameMessageImpl(this.field0) : super._();

  @override
  final RenameMessage field0;

  @override
  String toString() {
    return 'Message.renameMessage(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_RenameMessageImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_RenameMessageImplCopyWith<_$Message_RenameMessageImpl>
      get copyWith => __$$Message_RenameMessageImplCopyWithImpl<
          _$Message_RenameMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return renameMessage(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return renameMessage?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (renameMessage != null) {
      return renameMessage(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return renameMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return renameMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (renameMessage != null) {
      return renameMessage(this);
    }
    return orElse();
  }
}

abstract class Message_RenameMessage extends Message {
  const factory Message_RenameMessage(final RenameMessage field0) =
      _$Message_RenameMessageImpl;
  const Message_RenameMessage._() : super._();

  RenameMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_RenameMessageImplCopyWith<_$Message_RenameMessageImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_ChangeParticipantsImplCopyWith<$Res> {
  factory _$$Message_ChangeParticipantsImplCopyWith(
          _$Message_ChangeParticipantsImpl value,
          $Res Function(_$Message_ChangeParticipantsImpl) then) =
      __$$Message_ChangeParticipantsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ChangeParticipantMessage field0});
}

/// @nodoc
class __$$Message_ChangeParticipantsImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_ChangeParticipantsImpl>
    implements _$$Message_ChangeParticipantsImplCopyWith<$Res> {
  __$$Message_ChangeParticipantsImplCopyWithImpl(
      _$Message_ChangeParticipantsImpl _value,
      $Res Function(_$Message_ChangeParticipantsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_ChangeParticipantsImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ChangeParticipantMessage,
    ));
  }
}

/// @nodoc

class _$Message_ChangeParticipantsImpl extends Message_ChangeParticipants {
  const _$Message_ChangeParticipantsImpl(this.field0) : super._();

  @override
  final ChangeParticipantMessage field0;

  @override
  String toString() {
    return 'Message.changeParticipants(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_ChangeParticipantsImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_ChangeParticipantsImplCopyWith<_$Message_ChangeParticipantsImpl>
      get copyWith => __$$Message_ChangeParticipantsImplCopyWithImpl<
          _$Message_ChangeParticipantsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return changeParticipants(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return changeParticipants?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (changeParticipants != null) {
      return changeParticipants(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return changeParticipants(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return changeParticipants?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (changeParticipants != null) {
      return changeParticipants(this);
    }
    return orElse();
  }
}

abstract class Message_ChangeParticipants extends Message {
  const factory Message_ChangeParticipants(
      final ChangeParticipantMessage field0) = _$Message_ChangeParticipantsImpl;
  const Message_ChangeParticipants._() : super._();

  ChangeParticipantMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_ChangeParticipantsImplCopyWith<_$Message_ChangeParticipantsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_ReactImplCopyWith<$Res> {
  factory _$$Message_ReactImplCopyWith(
          _$Message_ReactImpl value, $Res Function(_$Message_ReactImpl) then) =
      __$$Message_ReactImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ReactMessage field0});
}

/// @nodoc
class __$$Message_ReactImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_ReactImpl>
    implements _$$Message_ReactImplCopyWith<$Res> {
  __$$Message_ReactImplCopyWithImpl(
      _$Message_ReactImpl _value, $Res Function(_$Message_ReactImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_ReactImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ReactMessage,
    ));
  }
}

/// @nodoc

class _$Message_ReactImpl extends Message_React {
  const _$Message_ReactImpl(this.field0) : super._();

  @override
  final ReactMessage field0;

  @override
  String toString() {
    return 'Message.react(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_ReactImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_ReactImplCopyWith<_$Message_ReactImpl> get copyWith =>
      __$$Message_ReactImplCopyWithImpl<_$Message_ReactImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return react(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return react?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (react != null) {
      return react(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return react(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return react?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (react != null) {
      return react(this);
    }
    return orElse();
  }
}

abstract class Message_React extends Message {
  const factory Message_React(final ReactMessage field0) = _$Message_ReactImpl;
  const Message_React._() : super._();

  ReactMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_ReactImplCopyWith<_$Message_ReactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_DeliveredImplCopyWith<$Res> {
  factory _$$Message_DeliveredImplCopyWith(_$Message_DeliveredImpl value,
          $Res Function(_$Message_DeliveredImpl) then) =
      __$$Message_DeliveredImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_DeliveredImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_DeliveredImpl>
    implements _$$Message_DeliveredImplCopyWith<$Res> {
  __$$Message_DeliveredImplCopyWithImpl(_$Message_DeliveredImpl _value,
      $Res Function(_$Message_DeliveredImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_DeliveredImpl extends Message_Delivered {
  const _$Message_DeliveredImpl() : super._();

  @override
  String toString() {
    return 'Message.delivered()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Message_DeliveredImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return delivered();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return delivered?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (delivered != null) {
      return delivered();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return delivered(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return delivered?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (delivered != null) {
      return delivered(this);
    }
    return orElse();
  }
}

abstract class Message_Delivered extends Message {
  const factory Message_Delivered() = _$Message_DeliveredImpl;
  const Message_Delivered._() : super._();
}

/// @nodoc
abstract class _$$Message_ReadImplCopyWith<$Res> {
  factory _$$Message_ReadImplCopyWith(
          _$Message_ReadImpl value, $Res Function(_$Message_ReadImpl) then) =
      __$$Message_ReadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_ReadImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_ReadImpl>
    implements _$$Message_ReadImplCopyWith<$Res> {
  __$$Message_ReadImplCopyWithImpl(
      _$Message_ReadImpl _value, $Res Function(_$Message_ReadImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_ReadImpl extends Message_Read {
  const _$Message_ReadImpl() : super._();

  @override
  String toString() {
    return 'Message.read()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Message_ReadImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return read();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return read?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (read != null) {
      return read();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return read(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return read?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (read != null) {
      return read(this);
    }
    return orElse();
  }
}

abstract class Message_Read extends Message {
  const factory Message_Read() = _$Message_ReadImpl;
  const Message_Read._() : super._();
}

/// @nodoc
abstract class _$$Message_TypingImplCopyWith<$Res> {
  factory _$$Message_TypingImplCopyWith(_$Message_TypingImpl value,
          $Res Function(_$Message_TypingImpl) then) =
      __$$Message_TypingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_TypingImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_TypingImpl>
    implements _$$Message_TypingImplCopyWith<$Res> {
  __$$Message_TypingImplCopyWithImpl(
      _$Message_TypingImpl _value, $Res Function(_$Message_TypingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_TypingImpl extends Message_Typing {
  const _$Message_TypingImpl() : super._();

  @override
  String toString() {
    return 'Message.typing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Message_TypingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return typing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return typing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (typing != null) {
      return typing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return typing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return typing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (typing != null) {
      return typing(this);
    }
    return orElse();
  }
}

abstract class Message_Typing extends Message {
  const factory Message_Typing() = _$Message_TypingImpl;
  const Message_Typing._() : super._();
}

/// @nodoc
abstract class _$$Message_UnsendImplCopyWith<$Res> {
  factory _$$Message_UnsendImplCopyWith(_$Message_UnsendImpl value,
          $Res Function(_$Message_UnsendImpl) then) =
      __$$Message_UnsendImplCopyWithImpl<$Res>;
  @useResult
  $Res call({UnsendMessage field0});
}

/// @nodoc
class __$$Message_UnsendImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_UnsendImpl>
    implements _$$Message_UnsendImplCopyWith<$Res> {
  __$$Message_UnsendImplCopyWithImpl(
      _$Message_UnsendImpl _value, $Res Function(_$Message_UnsendImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_UnsendImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as UnsendMessage,
    ));
  }
}

/// @nodoc

class _$Message_UnsendImpl extends Message_Unsend {
  const _$Message_UnsendImpl(this.field0) : super._();

  @override
  final UnsendMessage field0;

  @override
  String toString() {
    return 'Message.unsend(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_UnsendImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_UnsendImplCopyWith<_$Message_UnsendImpl> get copyWith =>
      __$$Message_UnsendImplCopyWithImpl<_$Message_UnsendImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return unsend(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return unsend?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (unsend != null) {
      return unsend(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return unsend(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return unsend?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (unsend != null) {
      return unsend(this);
    }
    return orElse();
  }
}

abstract class Message_Unsend extends Message {
  const factory Message_Unsend(final UnsendMessage field0) =
      _$Message_UnsendImpl;
  const Message_Unsend._() : super._();

  UnsendMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_UnsendImplCopyWith<_$Message_UnsendImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_EditImplCopyWith<$Res> {
  factory _$$Message_EditImplCopyWith(
          _$Message_EditImpl value, $Res Function(_$Message_EditImpl) then) =
      __$$Message_EditImplCopyWithImpl<$Res>;
  @useResult
  $Res call({EditMessage field0});
}

/// @nodoc
class __$$Message_EditImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_EditImpl>
    implements _$$Message_EditImplCopyWith<$Res> {
  __$$Message_EditImplCopyWithImpl(
      _$Message_EditImpl _value, $Res Function(_$Message_EditImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_EditImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as EditMessage,
    ));
  }
}

/// @nodoc

class _$Message_EditImpl extends Message_Edit {
  const _$Message_EditImpl(this.field0) : super._();

  @override
  final EditMessage field0;

  @override
  String toString() {
    return 'Message.edit(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_EditImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_EditImplCopyWith<_$Message_EditImpl> get copyWith =>
      __$$Message_EditImplCopyWithImpl<_$Message_EditImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return edit(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return edit?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (edit != null) {
      return edit(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return edit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return edit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (edit != null) {
      return edit(this);
    }
    return orElse();
  }
}

abstract class Message_Edit extends Message {
  const factory Message_Edit(final EditMessage field0) = _$Message_EditImpl;
  const Message_Edit._() : super._();

  EditMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_EditImplCopyWith<_$Message_EditImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_IconChangeImplCopyWith<$Res> {
  factory _$$Message_IconChangeImplCopyWith(_$Message_IconChangeImpl value,
          $Res Function(_$Message_IconChangeImpl) then) =
      __$$Message_IconChangeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({IconChangeMessage field0});
}

/// @nodoc
class __$$Message_IconChangeImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_IconChangeImpl>
    implements _$$Message_IconChangeImplCopyWith<$Res> {
  __$$Message_IconChangeImplCopyWithImpl(_$Message_IconChangeImpl _value,
      $Res Function(_$Message_IconChangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_IconChangeImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as IconChangeMessage,
    ));
  }
}

/// @nodoc

class _$Message_IconChangeImpl extends Message_IconChange {
  const _$Message_IconChangeImpl(this.field0) : super._();

  @override
  final IconChangeMessage field0;

  @override
  String toString() {
    return 'Message.iconChange(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_IconChangeImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_IconChangeImplCopyWith<_$Message_IconChangeImpl> get copyWith =>
      __$$Message_IconChangeImplCopyWithImpl<_$Message_IconChangeImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return iconChange(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return iconChange?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (iconChange != null) {
      return iconChange(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return iconChange(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return iconChange?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (iconChange != null) {
      return iconChange(this);
    }
    return orElse();
  }
}

abstract class Message_IconChange extends Message {
  const factory Message_IconChange(final IconChangeMessage field0) =
      _$Message_IconChangeImpl;
  const Message_IconChange._() : super._();

  IconChangeMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_IconChangeImplCopyWith<_$Message_IconChangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_StopTypingImplCopyWith<$Res> {
  factory _$$Message_StopTypingImplCopyWith(_$Message_StopTypingImpl value,
          $Res Function(_$Message_StopTypingImpl) then) =
      __$$Message_StopTypingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_StopTypingImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_StopTypingImpl>
    implements _$$Message_StopTypingImplCopyWith<$Res> {
  __$$Message_StopTypingImplCopyWithImpl(_$Message_StopTypingImpl _value,
      $Res Function(_$Message_StopTypingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_StopTypingImpl extends Message_StopTyping {
  const _$Message_StopTypingImpl() : super._();

  @override
  String toString() {
    return 'Message.stopTyping()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Message_StopTypingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return stopTyping();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return stopTyping?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (stopTyping != null) {
      return stopTyping();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return stopTyping(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return stopTyping?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (stopTyping != null) {
      return stopTyping(this);
    }
    return orElse();
  }
}

abstract class Message_StopTyping extends Message {
  const factory Message_StopTyping() = _$Message_StopTypingImpl;
  const Message_StopTyping._() : super._();
}

/// @nodoc
abstract class _$$Message_EnableSmsActivationImplCopyWith<$Res> {
  factory _$$Message_EnableSmsActivationImplCopyWith(
          _$Message_EnableSmsActivationImpl value,
          $Res Function(_$Message_EnableSmsActivationImpl) then) =
      __$$Message_EnableSmsActivationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class __$$Message_EnableSmsActivationImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_EnableSmsActivationImpl>
    implements _$$Message_EnableSmsActivationImplCopyWith<$Res> {
  __$$Message_EnableSmsActivationImplCopyWithImpl(
      _$Message_EnableSmsActivationImpl _value,
      $Res Function(_$Message_EnableSmsActivationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_EnableSmsActivationImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$Message_EnableSmsActivationImpl extends Message_EnableSmsActivation {
  const _$Message_EnableSmsActivationImpl(this.field0) : super._();

  @override
  final bool field0;

  @override
  String toString() {
    return 'Message.enableSmsActivation(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_EnableSmsActivationImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_EnableSmsActivationImplCopyWith<_$Message_EnableSmsActivationImpl>
      get copyWith => __$$Message_EnableSmsActivationImplCopyWithImpl<
          _$Message_EnableSmsActivationImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return enableSmsActivation(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return enableSmsActivation?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (enableSmsActivation != null) {
      return enableSmsActivation(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return enableSmsActivation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return enableSmsActivation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (enableSmsActivation != null) {
      return enableSmsActivation(this);
    }
    return orElse();
  }
}

abstract class Message_EnableSmsActivation extends Message {
  const factory Message_EnableSmsActivation(final bool field0) =
      _$Message_EnableSmsActivationImpl;
  const Message_EnableSmsActivation._() : super._();

  bool get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_EnableSmsActivationImplCopyWith<_$Message_EnableSmsActivationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_MessageReadOnDeviceImplCopyWith<$Res> {
  factory _$$Message_MessageReadOnDeviceImplCopyWith(
          _$Message_MessageReadOnDeviceImpl value,
          $Res Function(_$Message_MessageReadOnDeviceImpl) then) =
      __$$Message_MessageReadOnDeviceImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_MessageReadOnDeviceImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_MessageReadOnDeviceImpl>
    implements _$$Message_MessageReadOnDeviceImplCopyWith<$Res> {
  __$$Message_MessageReadOnDeviceImplCopyWithImpl(
      _$Message_MessageReadOnDeviceImpl _value,
      $Res Function(_$Message_MessageReadOnDeviceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_MessageReadOnDeviceImpl extends Message_MessageReadOnDevice {
  const _$Message_MessageReadOnDeviceImpl() : super._();

  @override
  String toString() {
    return 'Message.messageReadOnDevice()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_MessageReadOnDeviceImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return messageReadOnDevice();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return messageReadOnDevice?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (messageReadOnDevice != null) {
      return messageReadOnDevice();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return messageReadOnDevice(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return messageReadOnDevice?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (messageReadOnDevice != null) {
      return messageReadOnDevice(this);
    }
    return orElse();
  }
}

abstract class Message_MessageReadOnDevice extends Message {
  const factory Message_MessageReadOnDevice() =
      _$Message_MessageReadOnDeviceImpl;
  const Message_MessageReadOnDevice._() : super._();
}

/// @nodoc
abstract class _$$Message_SmsConfirmSentImplCopyWith<$Res> {
  factory _$$Message_SmsConfirmSentImplCopyWith(
          _$Message_SmsConfirmSentImpl value,
          $Res Function(_$Message_SmsConfirmSentImpl) then) =
      __$$Message_SmsConfirmSentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class __$$Message_SmsConfirmSentImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_SmsConfirmSentImpl>
    implements _$$Message_SmsConfirmSentImplCopyWith<$Res> {
  __$$Message_SmsConfirmSentImplCopyWithImpl(
      _$Message_SmsConfirmSentImpl _value,
      $Res Function(_$Message_SmsConfirmSentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_SmsConfirmSentImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$Message_SmsConfirmSentImpl extends Message_SmsConfirmSent {
  const _$Message_SmsConfirmSentImpl(this.field0) : super._();

  @override
  final bool field0;

  @override
  String toString() {
    return 'Message.smsConfirmSent(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_SmsConfirmSentImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_SmsConfirmSentImplCopyWith<_$Message_SmsConfirmSentImpl>
      get copyWith => __$$Message_SmsConfirmSentImplCopyWithImpl<
          _$Message_SmsConfirmSentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return smsConfirmSent(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return smsConfirmSent?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (smsConfirmSent != null) {
      return smsConfirmSent(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return smsConfirmSent(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return smsConfirmSent?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (smsConfirmSent != null) {
      return smsConfirmSent(this);
    }
    return orElse();
  }
}

abstract class Message_SmsConfirmSent extends Message {
  const factory Message_SmsConfirmSent(final bool field0) =
      _$Message_SmsConfirmSentImpl;
  const Message_SmsConfirmSent._() : super._();

  bool get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_SmsConfirmSentImplCopyWith<_$Message_SmsConfirmSentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_MarkUnreadImplCopyWith<$Res> {
  factory _$$Message_MarkUnreadImplCopyWith(_$Message_MarkUnreadImpl value,
          $Res Function(_$Message_MarkUnreadImpl) then) =
      __$$Message_MarkUnreadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_MarkUnreadImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_MarkUnreadImpl>
    implements _$$Message_MarkUnreadImplCopyWith<$Res> {
  __$$Message_MarkUnreadImplCopyWithImpl(_$Message_MarkUnreadImpl _value,
      $Res Function(_$Message_MarkUnreadImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_MarkUnreadImpl extends Message_MarkUnread {
  const _$Message_MarkUnreadImpl() : super._();

  @override
  String toString() {
    return 'Message.markUnread()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Message_MarkUnreadImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return markUnread();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return markUnread?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (markUnread != null) {
      return markUnread();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return markUnread(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return markUnread?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (markUnread != null) {
      return markUnread(this);
    }
    return orElse();
  }
}

abstract class Message_MarkUnread extends Message {
  const factory Message_MarkUnread() = _$Message_MarkUnreadImpl;
  const Message_MarkUnread._() : super._();
}

/// @nodoc
abstract class _$$Message_PeerCacheInvalidateImplCopyWith<$Res> {
  factory _$$Message_PeerCacheInvalidateImplCopyWith(
          _$Message_PeerCacheInvalidateImpl value,
          $Res Function(_$Message_PeerCacheInvalidateImpl) then) =
      __$$Message_PeerCacheInvalidateImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_PeerCacheInvalidateImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_PeerCacheInvalidateImpl>
    implements _$$Message_PeerCacheInvalidateImplCopyWith<$Res> {
  __$$Message_PeerCacheInvalidateImplCopyWithImpl(
      _$Message_PeerCacheInvalidateImpl _value,
      $Res Function(_$Message_PeerCacheInvalidateImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_PeerCacheInvalidateImpl extends Message_PeerCacheInvalidate {
  const _$Message_PeerCacheInvalidateImpl() : super._();

  @override
  String toString() {
    return 'Message.peerCacheInvalidate()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_PeerCacheInvalidateImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return peerCacheInvalidate();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return peerCacheInvalidate?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (peerCacheInvalidate != null) {
      return peerCacheInvalidate();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return peerCacheInvalidate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return peerCacheInvalidate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (peerCacheInvalidate != null) {
      return peerCacheInvalidate(this);
    }
    return orElse();
  }
}

abstract class Message_PeerCacheInvalidate extends Message {
  const factory Message_PeerCacheInvalidate() =
      _$Message_PeerCacheInvalidateImpl;
  const Message_PeerCacheInvalidate._() : super._();
}

/// @nodoc
abstract class _$$Message_UpdateExtensionImplCopyWith<$Res> {
  factory _$$Message_UpdateExtensionImplCopyWith(
          _$Message_UpdateExtensionImpl value,
          $Res Function(_$Message_UpdateExtensionImpl) then) =
      __$$Message_UpdateExtensionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({UpdateExtensionMessage field0});
}

/// @nodoc
class __$$Message_UpdateExtensionImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_UpdateExtensionImpl>
    implements _$$Message_UpdateExtensionImplCopyWith<$Res> {
  __$$Message_UpdateExtensionImplCopyWithImpl(
      _$Message_UpdateExtensionImpl _value,
      $Res Function(_$Message_UpdateExtensionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_UpdateExtensionImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as UpdateExtensionMessage,
    ));
  }
}

/// @nodoc

class _$Message_UpdateExtensionImpl extends Message_UpdateExtension {
  const _$Message_UpdateExtensionImpl(this.field0) : super._();

  @override
  final UpdateExtensionMessage field0;

  @override
  String toString() {
    return 'Message.updateExtension(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_UpdateExtensionImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_UpdateExtensionImplCopyWith<_$Message_UpdateExtensionImpl>
      get copyWith => __$$Message_UpdateExtensionImplCopyWithImpl<
          _$Message_UpdateExtensionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return updateExtension(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return updateExtension?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (updateExtension != null) {
      return updateExtension(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return updateExtension(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return updateExtension?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (updateExtension != null) {
      return updateExtension(this);
    }
    return orElse();
  }
}

abstract class Message_UpdateExtension extends Message {
  const factory Message_UpdateExtension(final UpdateExtensionMessage field0) =
      _$Message_UpdateExtensionImpl;
  const Message_UpdateExtension._() : super._();

  UpdateExtensionMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_UpdateExtensionImplCopyWith<_$Message_UpdateExtensionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_ErrorImplCopyWith<$Res> {
  factory _$$Message_ErrorImplCopyWith(
          _$Message_ErrorImpl value, $Res Function(_$Message_ErrorImpl) then) =
      __$$Message_ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ErrorMessage field0});
}

/// @nodoc
class __$$Message_ErrorImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_ErrorImpl>
    implements _$$Message_ErrorImplCopyWith<$Res> {
  __$$Message_ErrorImplCopyWithImpl(
      _$Message_ErrorImpl _value, $Res Function(_$Message_ErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_ErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ErrorMessage,
    ));
  }
}

/// @nodoc

class _$Message_ErrorImpl extends Message_Error {
  const _$Message_ErrorImpl(this.field0) : super._();

  @override
  final ErrorMessage field0;

  @override
  String toString() {
    return 'Message.error(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_ErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_ErrorImplCopyWith<_$Message_ErrorImpl> get copyWith =>
      __$$Message_ErrorImplCopyWithImpl<_$Message_ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return error(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return error?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class Message_Error extends Message {
  const factory Message_Error(final ErrorMessage field0) = _$Message_ErrorImpl;
  const Message_Error._() : super._();

  ErrorMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_ErrorImplCopyWith<_$Message_ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_MoveToRecycleBinImplCopyWith<$Res> {
  factory _$$Message_MoveToRecycleBinImplCopyWith(
          _$Message_MoveToRecycleBinImpl value,
          $Res Function(_$Message_MoveToRecycleBinImpl) then) =
      __$$Message_MoveToRecycleBinImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MoveToRecycleBinMessage field0});
}

/// @nodoc
class __$$Message_MoveToRecycleBinImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_MoveToRecycleBinImpl>
    implements _$$Message_MoveToRecycleBinImplCopyWith<$Res> {
  __$$Message_MoveToRecycleBinImplCopyWithImpl(
      _$Message_MoveToRecycleBinImpl _value,
      $Res Function(_$Message_MoveToRecycleBinImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_MoveToRecycleBinImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MoveToRecycleBinMessage,
    ));
  }
}

/// @nodoc

class _$Message_MoveToRecycleBinImpl extends Message_MoveToRecycleBin {
  const _$Message_MoveToRecycleBinImpl(this.field0) : super._();

  @override
  final MoveToRecycleBinMessage field0;

  @override
  String toString() {
    return 'Message.moveToRecycleBin(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_MoveToRecycleBinImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_MoveToRecycleBinImplCopyWith<_$Message_MoveToRecycleBinImpl>
      get copyWith => __$$Message_MoveToRecycleBinImplCopyWithImpl<
          _$Message_MoveToRecycleBinImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return moveToRecycleBin(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return moveToRecycleBin?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (moveToRecycleBin != null) {
      return moveToRecycleBin(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return moveToRecycleBin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return moveToRecycleBin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (moveToRecycleBin != null) {
      return moveToRecycleBin(this);
    }
    return orElse();
  }
}

abstract class Message_MoveToRecycleBin extends Message {
  const factory Message_MoveToRecycleBin(final MoveToRecycleBinMessage field0) =
      _$Message_MoveToRecycleBinImpl;
  const Message_MoveToRecycleBin._() : super._();

  MoveToRecycleBinMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_MoveToRecycleBinImplCopyWith<_$Message_MoveToRecycleBinImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_RecoverChatImplCopyWith<$Res> {
  factory _$$Message_RecoverChatImplCopyWith(_$Message_RecoverChatImpl value,
          $Res Function(_$Message_RecoverChatImpl) then) =
      __$$Message_RecoverChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({OperatedChat field0});
}

/// @nodoc
class __$$Message_RecoverChatImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_RecoverChatImpl>
    implements _$$Message_RecoverChatImplCopyWith<$Res> {
  __$$Message_RecoverChatImplCopyWithImpl(_$Message_RecoverChatImpl _value,
      $Res Function(_$Message_RecoverChatImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_RecoverChatImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as OperatedChat,
    ));
  }
}

/// @nodoc

class _$Message_RecoverChatImpl extends Message_RecoverChat {
  const _$Message_RecoverChatImpl(this.field0) : super._();

  @override
  final OperatedChat field0;

  @override
  String toString() {
    return 'Message.recoverChat(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_RecoverChatImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_RecoverChatImplCopyWith<_$Message_RecoverChatImpl> get copyWith =>
      __$$Message_RecoverChatImplCopyWithImpl<_$Message_RecoverChatImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return recoverChat(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return recoverChat?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (recoverChat != null) {
      return recoverChat(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return recoverChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return recoverChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (recoverChat != null) {
      return recoverChat(this);
    }
    return orElse();
  }
}

abstract class Message_RecoverChat extends Message {
  const factory Message_RecoverChat(final OperatedChat field0) =
      _$Message_RecoverChatImpl;
  const Message_RecoverChat._() : super._();

  OperatedChat get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_RecoverChatImplCopyWith<_$Message_RecoverChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_PermanentDeleteImplCopyWith<$Res> {
  factory _$$Message_PermanentDeleteImplCopyWith(
          _$Message_PermanentDeleteImpl value,
          $Res Function(_$Message_PermanentDeleteImpl) then) =
      __$$Message_PermanentDeleteImplCopyWithImpl<$Res>;
  @useResult
  $Res call({PermanentDeleteMessage field0});
}

/// @nodoc
class __$$Message_PermanentDeleteImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_PermanentDeleteImpl>
    implements _$$Message_PermanentDeleteImplCopyWith<$Res> {
  __$$Message_PermanentDeleteImplCopyWithImpl(
      _$Message_PermanentDeleteImpl _value,
      $Res Function(_$Message_PermanentDeleteImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Message_PermanentDeleteImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as PermanentDeleteMessage,
    ));
  }
}

/// @nodoc

class _$Message_PermanentDeleteImpl extends Message_PermanentDelete {
  const _$Message_PermanentDeleteImpl(this.field0) : super._();

  @override
  final PermanentDeleteMessage field0;

  @override
  String toString() {
    return 'Message.permanentDelete(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Message_PermanentDeleteImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Message_PermanentDeleteImplCopyWith<_$Message_PermanentDeleteImpl>
      get copyWith => __$$Message_PermanentDeleteImplCopyWithImpl<
          _$Message_PermanentDeleteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return permanentDelete(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return permanentDelete?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (permanentDelete != null) {
      return permanentDelete(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return permanentDelete(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return permanentDelete?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (permanentDelete != null) {
      return permanentDelete(this);
    }
    return orElse();
  }
}

abstract class Message_PermanentDelete extends Message {
  const factory Message_PermanentDelete(final PermanentDeleteMessage field0) =
      _$Message_PermanentDeleteImpl;
  const Message_PermanentDelete._() : super._();

  PermanentDeleteMessage get field0;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Message_PermanentDeleteImplCopyWith<_$Message_PermanentDeleteImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Message_UnscheduleImplCopyWith<$Res> {
  factory _$$Message_UnscheduleImplCopyWith(_$Message_UnscheduleImpl value,
          $Res Function(_$Message_UnscheduleImpl) then) =
      __$$Message_UnscheduleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Message_UnscheduleImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$Message_UnscheduleImpl>
    implements _$$Message_UnscheduleImplCopyWith<$Res> {
  __$$Message_UnscheduleImplCopyWithImpl(_$Message_UnscheduleImpl _value,
      $Res Function(_$Message_UnscheduleImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Message_UnscheduleImpl extends Message_Unschedule {
  const _$Message_UnscheduleImpl() : super._();

  @override
  String toString() {
    return 'Message.unschedule()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Message_UnscheduleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NormalMessage field0) message,
    required TResult Function(RenameMessage field0) renameMessage,
    required TResult Function(ChangeParticipantMessage field0)
        changeParticipants,
    required TResult Function(ReactMessage field0) react,
    required TResult Function() delivered,
    required TResult Function() read,
    required TResult Function() typing,
    required TResult Function(UnsendMessage field0) unsend,
    required TResult Function(EditMessage field0) edit,
    required TResult Function(IconChangeMessage field0) iconChange,
    required TResult Function() stopTyping,
    required TResult Function(bool field0) enableSmsActivation,
    required TResult Function() messageReadOnDevice,
    required TResult Function(bool field0) smsConfirmSent,
    required TResult Function() markUnread,
    required TResult Function() peerCacheInvalidate,
    required TResult Function(UpdateExtensionMessage field0) updateExtension,
    required TResult Function(ErrorMessage field0) error,
    required TResult Function(MoveToRecycleBinMessage field0) moveToRecycleBin,
    required TResult Function(OperatedChat field0) recoverChat,
    required TResult Function(PermanentDeleteMessage field0) permanentDelete,
    required TResult Function() unschedule,
  }) {
    return unschedule();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NormalMessage field0)? message,
    TResult? Function(RenameMessage field0)? renameMessage,
    TResult? Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult? Function(ReactMessage field0)? react,
    TResult? Function()? delivered,
    TResult? Function()? read,
    TResult? Function()? typing,
    TResult? Function(UnsendMessage field0)? unsend,
    TResult? Function(EditMessage field0)? edit,
    TResult? Function(IconChangeMessage field0)? iconChange,
    TResult? Function()? stopTyping,
    TResult? Function(bool field0)? enableSmsActivation,
    TResult? Function()? messageReadOnDevice,
    TResult? Function(bool field0)? smsConfirmSent,
    TResult? Function()? markUnread,
    TResult? Function()? peerCacheInvalidate,
    TResult? Function(UpdateExtensionMessage field0)? updateExtension,
    TResult? Function(ErrorMessage field0)? error,
    TResult? Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult? Function(OperatedChat field0)? recoverChat,
    TResult? Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult? Function()? unschedule,
  }) {
    return unschedule?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NormalMessage field0)? message,
    TResult Function(RenameMessage field0)? renameMessage,
    TResult Function(ChangeParticipantMessage field0)? changeParticipants,
    TResult Function(ReactMessage field0)? react,
    TResult Function()? delivered,
    TResult Function()? read,
    TResult Function()? typing,
    TResult Function(UnsendMessage field0)? unsend,
    TResult Function(EditMessage field0)? edit,
    TResult Function(IconChangeMessage field0)? iconChange,
    TResult Function()? stopTyping,
    TResult Function(bool field0)? enableSmsActivation,
    TResult Function()? messageReadOnDevice,
    TResult Function(bool field0)? smsConfirmSent,
    TResult Function()? markUnread,
    TResult Function()? peerCacheInvalidate,
    TResult Function(UpdateExtensionMessage field0)? updateExtension,
    TResult Function(ErrorMessage field0)? error,
    TResult Function(MoveToRecycleBinMessage field0)? moveToRecycleBin,
    TResult Function(OperatedChat field0)? recoverChat,
    TResult Function(PermanentDeleteMessage field0)? permanentDelete,
    TResult Function()? unschedule,
    required TResult orElse(),
  }) {
    if (unschedule != null) {
      return unschedule();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Message_Message value) message,
    required TResult Function(Message_RenameMessage value) renameMessage,
    required TResult Function(Message_ChangeParticipants value)
        changeParticipants,
    required TResult Function(Message_React value) react,
    required TResult Function(Message_Delivered value) delivered,
    required TResult Function(Message_Read value) read,
    required TResult Function(Message_Typing value) typing,
    required TResult Function(Message_Unsend value) unsend,
    required TResult Function(Message_Edit value) edit,
    required TResult Function(Message_IconChange value) iconChange,
    required TResult Function(Message_StopTyping value) stopTyping,
    required TResult Function(Message_EnableSmsActivation value)
        enableSmsActivation,
    required TResult Function(Message_MessageReadOnDevice value)
        messageReadOnDevice,
    required TResult Function(Message_SmsConfirmSent value) smsConfirmSent,
    required TResult Function(Message_MarkUnread value) markUnread,
    required TResult Function(Message_PeerCacheInvalidate value)
        peerCacheInvalidate,
    required TResult Function(Message_UpdateExtension value) updateExtension,
    required TResult Function(Message_Error value) error,
    required TResult Function(Message_MoveToRecycleBin value) moveToRecycleBin,
    required TResult Function(Message_RecoverChat value) recoverChat,
    required TResult Function(Message_PermanentDelete value) permanentDelete,
    required TResult Function(Message_Unschedule value) unschedule,
  }) {
    return unschedule(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Message_Message value)? message,
    TResult? Function(Message_RenameMessage value)? renameMessage,
    TResult? Function(Message_ChangeParticipants value)? changeParticipants,
    TResult? Function(Message_React value)? react,
    TResult? Function(Message_Delivered value)? delivered,
    TResult? Function(Message_Read value)? read,
    TResult? Function(Message_Typing value)? typing,
    TResult? Function(Message_Unsend value)? unsend,
    TResult? Function(Message_Edit value)? edit,
    TResult? Function(Message_IconChange value)? iconChange,
    TResult? Function(Message_StopTyping value)? stopTyping,
    TResult? Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult? Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult? Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult? Function(Message_MarkUnread value)? markUnread,
    TResult? Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult? Function(Message_UpdateExtension value)? updateExtension,
    TResult? Function(Message_Error value)? error,
    TResult? Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult? Function(Message_RecoverChat value)? recoverChat,
    TResult? Function(Message_PermanentDelete value)? permanentDelete,
    TResult? Function(Message_Unschedule value)? unschedule,
  }) {
    return unschedule?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Message_Message value)? message,
    TResult Function(Message_RenameMessage value)? renameMessage,
    TResult Function(Message_ChangeParticipants value)? changeParticipants,
    TResult Function(Message_React value)? react,
    TResult Function(Message_Delivered value)? delivered,
    TResult Function(Message_Read value)? read,
    TResult Function(Message_Typing value)? typing,
    TResult Function(Message_Unsend value)? unsend,
    TResult Function(Message_Edit value)? edit,
    TResult Function(Message_IconChange value)? iconChange,
    TResult Function(Message_StopTyping value)? stopTyping,
    TResult Function(Message_EnableSmsActivation value)? enableSmsActivation,
    TResult Function(Message_MessageReadOnDevice value)? messageReadOnDevice,
    TResult Function(Message_SmsConfirmSent value)? smsConfirmSent,
    TResult Function(Message_MarkUnread value)? markUnread,
    TResult Function(Message_PeerCacheInvalidate value)? peerCacheInvalidate,
    TResult Function(Message_UpdateExtension value)? updateExtension,
    TResult Function(Message_Error value)? error,
    TResult Function(Message_MoveToRecycleBin value)? moveToRecycleBin,
    TResult Function(Message_RecoverChat value)? recoverChat,
    TResult Function(Message_PermanentDelete value)? permanentDelete,
    TResult Function(Message_Unschedule value)? unschedule,
    required TResult orElse(),
  }) {
    if (unschedule != null) {
      return unschedule(this);
    }
    return orElse();
  }
}

abstract class Message_Unschedule extends Message {
  const factory Message_Unschedule() = _$Message_UnscheduleImpl;
  const Message_Unschedule._() : super._();
}

/// @nodoc
mixin _$MessagePart {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0, TextFormat field1) text,
    required TResult Function(Attachment field0) attachment,
    required TResult Function(String field0, String field1) mention,
    required TResult Function(String field0) object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0, TextFormat field1)? text,
    TResult? Function(Attachment field0)? attachment,
    TResult? Function(String field0, String field1)? mention,
    TResult? Function(String field0)? object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0, TextFormat field1)? text,
    TResult Function(Attachment field0)? attachment,
    TResult Function(String field0, String field1)? mention,
    TResult Function(String field0)? object,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessagePart_Text value) text,
    required TResult Function(MessagePart_Attachment value) attachment,
    required TResult Function(MessagePart_Mention value) mention,
    required TResult Function(MessagePart_Object value) object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessagePart_Text value)? text,
    TResult? Function(MessagePart_Attachment value)? attachment,
    TResult? Function(MessagePart_Mention value)? mention,
    TResult? Function(MessagePart_Object value)? object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessagePart_Text value)? text,
    TResult Function(MessagePart_Attachment value)? attachment,
    TResult Function(MessagePart_Mention value)? mention,
    TResult Function(MessagePart_Object value)? object,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessagePartCopyWith<$Res> {
  factory $MessagePartCopyWith(
          MessagePart value, $Res Function(MessagePart) then) =
      _$MessagePartCopyWithImpl<$Res, MessagePart>;
}

/// @nodoc
class _$MessagePartCopyWithImpl<$Res, $Val extends MessagePart>
    implements $MessagePartCopyWith<$Res> {
  _$MessagePartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MessagePart_TextImplCopyWith<$Res> {
  factory _$$MessagePart_TextImplCopyWith(_$MessagePart_TextImpl value,
          $Res Function(_$MessagePart_TextImpl) then) =
      __$$MessagePart_TextImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0, TextFormat field1});

  $TextFormatCopyWith<$Res> get field1;
}

/// @nodoc
class __$$MessagePart_TextImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$MessagePart_TextImpl>
    implements _$$MessagePart_TextImplCopyWith<$Res> {
  __$$MessagePart_TextImplCopyWithImpl(_$MessagePart_TextImpl _value,
      $Res Function(_$MessagePart_TextImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
    Object? field1 = null,
  }) {
    return _then(_$MessagePart_TextImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
      null == field1
          ? _value.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as TextFormat,
    ));
  }

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TextFormatCopyWith<$Res> get field1 {
    return $TextFormatCopyWith<$Res>(_value.field1, (value) {
      return _then(_value.copyWith(field1: value));
    });
  }
}

/// @nodoc

class _$MessagePart_TextImpl extends MessagePart_Text {
  const _$MessagePart_TextImpl(this.field0, this.field1) : super._();

  @override
  final String field0;
  @override
  final TextFormat field1;

  @override
  String toString() {
    return 'MessagePart.text(field0: $field0, field1: $field1)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagePart_TextImpl &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0, field1);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagePart_TextImplCopyWith<_$MessagePart_TextImpl> get copyWith =>
      __$$MessagePart_TextImplCopyWithImpl<_$MessagePart_TextImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0, TextFormat field1) text,
    required TResult Function(Attachment field0) attachment,
    required TResult Function(String field0, String field1) mention,
    required TResult Function(String field0) object,
  }) {
    return text(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0, TextFormat field1)? text,
    TResult? Function(Attachment field0)? attachment,
    TResult? Function(String field0, String field1)? mention,
    TResult? Function(String field0)? object,
  }) {
    return text?.call(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0, TextFormat field1)? text,
    TResult Function(Attachment field0)? attachment,
    TResult Function(String field0, String field1)? mention,
    TResult Function(String field0)? object,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(field0, field1);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessagePart_Text value) text,
    required TResult Function(MessagePart_Attachment value) attachment,
    required TResult Function(MessagePart_Mention value) mention,
    required TResult Function(MessagePart_Object value) object,
  }) {
    return text(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessagePart_Text value)? text,
    TResult? Function(MessagePart_Attachment value)? attachment,
    TResult? Function(MessagePart_Mention value)? mention,
    TResult? Function(MessagePart_Object value)? object,
  }) {
    return text?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessagePart_Text value)? text,
    TResult Function(MessagePart_Attachment value)? attachment,
    TResult Function(MessagePart_Mention value)? mention,
    TResult Function(MessagePart_Object value)? object,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this);
    }
    return orElse();
  }
}

abstract class MessagePart_Text extends MessagePart {
  const factory MessagePart_Text(final String field0, final TextFormat field1) =
      _$MessagePart_TextImpl;
  const MessagePart_Text._() : super._();

  @override
  String get field0;
  TextFormat get field1;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessagePart_TextImplCopyWith<_$MessagePart_TextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessagePart_AttachmentImplCopyWith<$Res> {
  factory _$$MessagePart_AttachmentImplCopyWith(
          _$MessagePart_AttachmentImpl value,
          $Res Function(_$MessagePart_AttachmentImpl) then) =
      __$$MessagePart_AttachmentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Attachment field0});
}

/// @nodoc
class __$$MessagePart_AttachmentImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$MessagePart_AttachmentImpl>
    implements _$$MessagePart_AttachmentImplCopyWith<$Res> {
  __$$MessagePart_AttachmentImplCopyWithImpl(
      _$MessagePart_AttachmentImpl _value,
      $Res Function(_$MessagePart_AttachmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$MessagePart_AttachmentImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Attachment,
    ));
  }
}

/// @nodoc

class _$MessagePart_AttachmentImpl extends MessagePart_Attachment {
  const _$MessagePart_AttachmentImpl(this.field0) : super._();

  @override
  final Attachment field0;

  @override
  String toString() {
    return 'MessagePart.attachment(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagePart_AttachmentImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagePart_AttachmentImplCopyWith<_$MessagePart_AttachmentImpl>
      get copyWith => __$$MessagePart_AttachmentImplCopyWithImpl<
          _$MessagePart_AttachmentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0, TextFormat field1) text,
    required TResult Function(Attachment field0) attachment,
    required TResult Function(String field0, String field1) mention,
    required TResult Function(String field0) object,
  }) {
    return attachment(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0, TextFormat field1)? text,
    TResult? Function(Attachment field0)? attachment,
    TResult? Function(String field0, String field1)? mention,
    TResult? Function(String field0)? object,
  }) {
    return attachment?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0, TextFormat field1)? text,
    TResult Function(Attachment field0)? attachment,
    TResult Function(String field0, String field1)? mention,
    TResult Function(String field0)? object,
    required TResult orElse(),
  }) {
    if (attachment != null) {
      return attachment(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessagePart_Text value) text,
    required TResult Function(MessagePart_Attachment value) attachment,
    required TResult Function(MessagePart_Mention value) mention,
    required TResult Function(MessagePart_Object value) object,
  }) {
    return attachment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessagePart_Text value)? text,
    TResult? Function(MessagePart_Attachment value)? attachment,
    TResult? Function(MessagePart_Mention value)? mention,
    TResult? Function(MessagePart_Object value)? object,
  }) {
    return attachment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessagePart_Text value)? text,
    TResult Function(MessagePart_Attachment value)? attachment,
    TResult Function(MessagePart_Mention value)? mention,
    TResult Function(MessagePart_Object value)? object,
    required TResult orElse(),
  }) {
    if (attachment != null) {
      return attachment(this);
    }
    return orElse();
  }
}

abstract class MessagePart_Attachment extends MessagePart {
  const factory MessagePart_Attachment(final Attachment field0) =
      _$MessagePart_AttachmentImpl;
  const MessagePart_Attachment._() : super._();

  @override
  Attachment get field0;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessagePart_AttachmentImplCopyWith<_$MessagePart_AttachmentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessagePart_MentionImplCopyWith<$Res> {
  factory _$$MessagePart_MentionImplCopyWith(_$MessagePart_MentionImpl value,
          $Res Function(_$MessagePart_MentionImpl) then) =
      __$$MessagePart_MentionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0, String field1});
}

/// @nodoc
class __$$MessagePart_MentionImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$MessagePart_MentionImpl>
    implements _$$MessagePart_MentionImplCopyWith<$Res> {
  __$$MessagePart_MentionImplCopyWithImpl(_$MessagePart_MentionImpl _value,
      $Res Function(_$MessagePart_MentionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
    Object? field1 = null,
  }) {
    return _then(_$MessagePart_MentionImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
      null == field1
          ? _value.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MessagePart_MentionImpl extends MessagePart_Mention {
  const _$MessagePart_MentionImpl(this.field0, this.field1) : super._();

  @override
  final String field0;
  @override
  final String field1;

  @override
  String toString() {
    return 'MessagePart.mention(field0: $field0, field1: $field1)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagePart_MentionImpl &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0, field1);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagePart_MentionImplCopyWith<_$MessagePart_MentionImpl> get copyWith =>
      __$$MessagePart_MentionImplCopyWithImpl<_$MessagePart_MentionImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0, TextFormat field1) text,
    required TResult Function(Attachment field0) attachment,
    required TResult Function(String field0, String field1) mention,
    required TResult Function(String field0) object,
  }) {
    return mention(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0, TextFormat field1)? text,
    TResult? Function(Attachment field0)? attachment,
    TResult? Function(String field0, String field1)? mention,
    TResult? Function(String field0)? object,
  }) {
    return mention?.call(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0, TextFormat field1)? text,
    TResult Function(Attachment field0)? attachment,
    TResult Function(String field0, String field1)? mention,
    TResult Function(String field0)? object,
    required TResult orElse(),
  }) {
    if (mention != null) {
      return mention(field0, field1);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessagePart_Text value) text,
    required TResult Function(MessagePart_Attachment value) attachment,
    required TResult Function(MessagePart_Mention value) mention,
    required TResult Function(MessagePart_Object value) object,
  }) {
    return mention(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessagePart_Text value)? text,
    TResult? Function(MessagePart_Attachment value)? attachment,
    TResult? Function(MessagePart_Mention value)? mention,
    TResult? Function(MessagePart_Object value)? object,
  }) {
    return mention?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessagePart_Text value)? text,
    TResult Function(MessagePart_Attachment value)? attachment,
    TResult Function(MessagePart_Mention value)? mention,
    TResult Function(MessagePart_Object value)? object,
    required TResult orElse(),
  }) {
    if (mention != null) {
      return mention(this);
    }
    return orElse();
  }
}

abstract class MessagePart_Mention extends MessagePart {
  const factory MessagePart_Mention(final String field0, final String field1) =
      _$MessagePart_MentionImpl;
  const MessagePart_Mention._() : super._();

  @override
  String get field0;
  String get field1;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessagePart_MentionImplCopyWith<_$MessagePart_MentionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessagePart_ObjectImplCopyWith<$Res> {
  factory _$$MessagePart_ObjectImplCopyWith(_$MessagePart_ObjectImpl value,
          $Res Function(_$MessagePart_ObjectImpl) then) =
      __$$MessagePart_ObjectImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$MessagePart_ObjectImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$MessagePart_ObjectImpl>
    implements _$$MessagePart_ObjectImplCopyWith<$Res> {
  __$$MessagePart_ObjectImplCopyWithImpl(_$MessagePart_ObjectImpl _value,
      $Res Function(_$MessagePart_ObjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$MessagePart_ObjectImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MessagePart_ObjectImpl extends MessagePart_Object {
  const _$MessagePart_ObjectImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'MessagePart.object(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagePart_ObjectImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagePart_ObjectImplCopyWith<_$MessagePart_ObjectImpl> get copyWith =>
      __$$MessagePart_ObjectImplCopyWithImpl<_$MessagePart_ObjectImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0, TextFormat field1) text,
    required TResult Function(Attachment field0) attachment,
    required TResult Function(String field0, String field1) mention,
    required TResult Function(String field0) object,
  }) {
    return object(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0, TextFormat field1)? text,
    TResult? Function(Attachment field0)? attachment,
    TResult? Function(String field0, String field1)? mention,
    TResult? Function(String field0)? object,
  }) {
    return object?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0, TextFormat field1)? text,
    TResult Function(Attachment field0)? attachment,
    TResult Function(String field0, String field1)? mention,
    TResult Function(String field0)? object,
    required TResult orElse(),
  }) {
    if (object != null) {
      return object(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessagePart_Text value) text,
    required TResult Function(MessagePart_Attachment value) attachment,
    required TResult Function(MessagePart_Mention value) mention,
    required TResult Function(MessagePart_Object value) object,
  }) {
    return object(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessagePart_Text value)? text,
    TResult? Function(MessagePart_Attachment value)? attachment,
    TResult? Function(MessagePart_Mention value)? mention,
    TResult? Function(MessagePart_Object value)? object,
  }) {
    return object?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessagePart_Text value)? text,
    TResult Function(MessagePart_Attachment value)? attachment,
    TResult Function(MessagePart_Mention value)? mention,
    TResult Function(MessagePart_Object value)? object,
    required TResult orElse(),
  }) {
    if (object != null) {
      return object(this);
    }
    return orElse();
  }
}

abstract class MessagePart_Object extends MessagePart {
  const factory MessagePart_Object(final String field0) =
      _$MessagePart_ObjectImpl;
  const MessagePart_Object._() : super._();

  @override
  String get field0;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessagePart_ObjectImplCopyWith<_$MessagePart_ObjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MessageTarget {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List field0) token,
    required TResult Function(String field0) uuid,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List field0)? token,
    TResult? Function(String field0)? uuid,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List field0)? token,
    TResult Function(String field0)? uuid,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTarget_Token value) token,
    required TResult Function(MessageTarget_Uuid value) uuid,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTarget_Token value)? token,
    TResult? Function(MessageTarget_Uuid value)? uuid,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTarget_Token value)? token,
    TResult Function(MessageTarget_Uuid value)? uuid,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageTargetCopyWith<$Res> {
  factory $MessageTargetCopyWith(
          MessageTarget value, $Res Function(MessageTarget) then) =
      _$MessageTargetCopyWithImpl<$Res, MessageTarget>;
}

/// @nodoc
class _$MessageTargetCopyWithImpl<$Res, $Val extends MessageTarget>
    implements $MessageTargetCopyWith<$Res> {
  _$MessageTargetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MessageTarget_TokenImplCopyWith<$Res> {
  factory _$$MessageTarget_TokenImplCopyWith(_$MessageTarget_TokenImpl value,
          $Res Function(_$MessageTarget_TokenImpl) then) =
      __$$MessageTarget_TokenImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Uint8List field0});
}

/// @nodoc
class __$$MessageTarget_TokenImplCopyWithImpl<$Res>
    extends _$MessageTargetCopyWithImpl<$Res, _$MessageTarget_TokenImpl>
    implements _$$MessageTarget_TokenImplCopyWith<$Res> {
  __$$MessageTarget_TokenImplCopyWithImpl(_$MessageTarget_TokenImpl _value,
      $Res Function(_$MessageTarget_TokenImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$MessageTarget_TokenImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc

class _$MessageTarget_TokenImpl extends MessageTarget_Token {
  const _$MessageTarget_TokenImpl(this.field0) : super._();

  @override
  final Uint8List field0;

  @override
  String toString() {
    return 'MessageTarget.token(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageTarget_TokenImpl &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageTarget_TokenImplCopyWith<_$MessageTarget_TokenImpl> get copyWith =>
      __$$MessageTarget_TokenImplCopyWithImpl<_$MessageTarget_TokenImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List field0) token,
    required TResult Function(String field0) uuid,
  }) {
    return token(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List field0)? token,
    TResult? Function(String field0)? uuid,
  }) {
    return token?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List field0)? token,
    TResult Function(String field0)? uuid,
    required TResult orElse(),
  }) {
    if (token != null) {
      return token(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTarget_Token value) token,
    required TResult Function(MessageTarget_Uuid value) uuid,
  }) {
    return token(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTarget_Token value)? token,
    TResult? Function(MessageTarget_Uuid value)? uuid,
  }) {
    return token?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTarget_Token value)? token,
    TResult Function(MessageTarget_Uuid value)? uuid,
    required TResult orElse(),
  }) {
    if (token != null) {
      return token(this);
    }
    return orElse();
  }
}

abstract class MessageTarget_Token extends MessageTarget {
  const factory MessageTarget_Token(final Uint8List field0) =
      _$MessageTarget_TokenImpl;
  const MessageTarget_Token._() : super._();

  @override
  Uint8List get field0;

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageTarget_TokenImplCopyWith<_$MessageTarget_TokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageTarget_UuidImplCopyWith<$Res> {
  factory _$$MessageTarget_UuidImplCopyWith(_$MessageTarget_UuidImpl value,
          $Res Function(_$MessageTarget_UuidImpl) then) =
      __$$MessageTarget_UuidImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$MessageTarget_UuidImplCopyWithImpl<$Res>
    extends _$MessageTargetCopyWithImpl<$Res, _$MessageTarget_UuidImpl>
    implements _$$MessageTarget_UuidImplCopyWith<$Res> {
  __$$MessageTarget_UuidImplCopyWithImpl(_$MessageTarget_UuidImpl _value,
      $Res Function(_$MessageTarget_UuidImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$MessageTarget_UuidImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MessageTarget_UuidImpl extends MessageTarget_Uuid {
  const _$MessageTarget_UuidImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'MessageTarget.uuid(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageTarget_UuidImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageTarget_UuidImplCopyWith<_$MessageTarget_UuidImpl> get copyWith =>
      __$$MessageTarget_UuidImplCopyWithImpl<_$MessageTarget_UuidImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List field0) token,
    required TResult Function(String field0) uuid,
  }) {
    return uuid(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List field0)? token,
    TResult? Function(String field0)? uuid,
  }) {
    return uuid?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List field0)? token,
    TResult Function(String field0)? uuid,
    required TResult orElse(),
  }) {
    if (uuid != null) {
      return uuid(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTarget_Token value) token,
    required TResult Function(MessageTarget_Uuid value) uuid,
  }) {
    return uuid(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTarget_Token value)? token,
    TResult? Function(MessageTarget_Uuid value)? uuid,
  }) {
    return uuid?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTarget_Token value)? token,
    TResult Function(MessageTarget_Uuid value)? uuid,
    required TResult orElse(),
  }) {
    if (uuid != null) {
      return uuid(this);
    }
    return orElse();
  }
}

abstract class MessageTarget_Uuid extends MessageTarget {
  const factory MessageTarget_Uuid(final String field0) =
      _$MessageTarget_UuidImpl;
  const MessageTarget_Uuid._() : super._();

  @override
  String get field0;

  /// Create a copy of MessageTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageTarget_UuidImplCopyWith<_$MessageTarget_UuidImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MessageType {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() iMessage,
    required TResult Function(
            bool isPhone, String usingNumber, String? fromHandle)
        sms,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? iMessage,
    TResult? Function(bool isPhone, String usingNumber, String? fromHandle)?
        sms,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? iMessage,
    TResult Function(bool isPhone, String usingNumber, String? fromHandle)? sms,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageType_IMessage value) iMessage,
    required TResult Function(MessageType_SMS value) sms,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageType_IMessage value)? iMessage,
    TResult? Function(MessageType_SMS value)? sms,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageType_IMessage value)? iMessage,
    TResult Function(MessageType_SMS value)? sms,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageTypeCopyWith<$Res> {
  factory $MessageTypeCopyWith(
          MessageType value, $Res Function(MessageType) then) =
      _$MessageTypeCopyWithImpl<$Res, MessageType>;
}

/// @nodoc
class _$MessageTypeCopyWithImpl<$Res, $Val extends MessageType>
    implements $MessageTypeCopyWith<$Res> {
  _$MessageTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MessageType_IMessageImplCopyWith<$Res> {
  factory _$$MessageType_IMessageImplCopyWith(_$MessageType_IMessageImpl value,
          $Res Function(_$MessageType_IMessageImpl) then) =
      __$$MessageType_IMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$MessageType_IMessageImplCopyWithImpl<$Res>
    extends _$MessageTypeCopyWithImpl<$Res, _$MessageType_IMessageImpl>
    implements _$$MessageType_IMessageImplCopyWith<$Res> {
  __$$MessageType_IMessageImplCopyWithImpl(_$MessageType_IMessageImpl _value,
      $Res Function(_$MessageType_IMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$MessageType_IMessageImpl extends MessageType_IMessage {
  const _$MessageType_IMessageImpl() : super._();

  @override
  String toString() {
    return 'MessageType.iMessage()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageType_IMessageImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() iMessage,
    required TResult Function(
            bool isPhone, String usingNumber, String? fromHandle)
        sms,
  }) {
    return iMessage();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? iMessage,
    TResult? Function(bool isPhone, String usingNumber, String? fromHandle)?
        sms,
  }) {
    return iMessage?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? iMessage,
    TResult Function(bool isPhone, String usingNumber, String? fromHandle)? sms,
    required TResult orElse(),
  }) {
    if (iMessage != null) {
      return iMessage();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageType_IMessage value) iMessage,
    required TResult Function(MessageType_SMS value) sms,
  }) {
    return iMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageType_IMessage value)? iMessage,
    TResult? Function(MessageType_SMS value)? sms,
  }) {
    return iMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageType_IMessage value)? iMessage,
    TResult Function(MessageType_SMS value)? sms,
    required TResult orElse(),
  }) {
    if (iMessage != null) {
      return iMessage(this);
    }
    return orElse();
  }
}

abstract class MessageType_IMessage extends MessageType {
  const factory MessageType_IMessage() = _$MessageType_IMessageImpl;
  const MessageType_IMessage._() : super._();
}

/// @nodoc
abstract class _$$MessageType_SMSImplCopyWith<$Res> {
  factory _$$MessageType_SMSImplCopyWith(_$MessageType_SMSImpl value,
          $Res Function(_$MessageType_SMSImpl) then) =
      __$$MessageType_SMSImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isPhone, String usingNumber, String? fromHandle});
}

/// @nodoc
class __$$MessageType_SMSImplCopyWithImpl<$Res>
    extends _$MessageTypeCopyWithImpl<$Res, _$MessageType_SMSImpl>
    implements _$$MessageType_SMSImplCopyWith<$Res> {
  __$$MessageType_SMSImplCopyWithImpl(
      _$MessageType_SMSImpl _value, $Res Function(_$MessageType_SMSImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPhone = null,
    Object? usingNumber = null,
    Object? fromHandle = freezed,
  }) {
    return _then(_$MessageType_SMSImpl(
      isPhone: null == isPhone
          ? _value.isPhone
          : isPhone // ignore: cast_nullable_to_non_nullable
              as bool,
      usingNumber: null == usingNumber
          ? _value.usingNumber
          : usingNumber // ignore: cast_nullable_to_non_nullable
              as String,
      fromHandle: freezed == fromHandle
          ? _value.fromHandle
          : fromHandle // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MessageType_SMSImpl extends MessageType_SMS {
  const _$MessageType_SMSImpl(
      {required this.isPhone, required this.usingNumber, this.fromHandle})
      : super._();

  @override
  final bool isPhone;
  @override
  final String usingNumber;
  @override
  final String? fromHandle;

  @override
  String toString() {
    return 'MessageType.sms(isPhone: $isPhone, usingNumber: $usingNumber, fromHandle: $fromHandle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageType_SMSImpl &&
            (identical(other.isPhone, isPhone) || other.isPhone == isPhone) &&
            (identical(other.usingNumber, usingNumber) ||
                other.usingNumber == usingNumber) &&
            (identical(other.fromHandle, fromHandle) ||
                other.fromHandle == fromHandle));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isPhone, usingNumber, fromHandle);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageType_SMSImplCopyWith<_$MessageType_SMSImpl> get copyWith =>
      __$$MessageType_SMSImplCopyWithImpl<_$MessageType_SMSImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() iMessage,
    required TResult Function(
            bool isPhone, String usingNumber, String? fromHandle)
        sms,
  }) {
    return sms(isPhone, usingNumber, fromHandle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? iMessage,
    TResult? Function(bool isPhone, String usingNumber, String? fromHandle)?
        sms,
  }) {
    return sms?.call(isPhone, usingNumber, fromHandle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? iMessage,
    TResult Function(bool isPhone, String usingNumber, String? fromHandle)? sms,
    required TResult orElse(),
  }) {
    if (sms != null) {
      return sms(isPhone, usingNumber, fromHandle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageType_IMessage value) iMessage,
    required TResult Function(MessageType_SMS value) sms,
  }) {
    return sms(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageType_IMessage value)? iMessage,
    TResult? Function(MessageType_SMS value)? sms,
  }) {
    return sms?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageType_IMessage value)? iMessage,
    TResult Function(MessageType_SMS value)? sms,
    required TResult orElse(),
  }) {
    if (sms != null) {
      return sms(this);
    }
    return orElse();
  }
}

abstract class MessageType_SMS extends MessageType {
  const factory MessageType_SMS(
      {required final bool isPhone,
      required final String usingNumber,
      final String? fromHandle}) = _$MessageType_SMSImpl;
  const MessageType_SMS._() : super._();

  bool get isPhone;
  String get usingNumber;
  String? get fromHandle;

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageType_SMSImplCopyWith<_$MessageType_SMSImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PartExtension {
  double get msgWidth => throw _privateConstructorUsedError;
  double get rotation => throw _privateConstructorUsedError;
  BigInt get sai => throw _privateConstructorUsedError;
  double get scale => throw _privateConstructorUsedError;
  bool? get update => throw _privateConstructorUsedError;
  BigInt get sli => throw _privateConstructorUsedError;
  double get normalizedX => throw _privateConstructorUsedError;
  double get normalizedY => throw _privateConstructorUsedError;
  BigInt get version => throw _privateConstructorUsedError;
  String get hash => throw _privateConstructorUsedError;
  BigInt get safi => throw _privateConstructorUsedError;
  int get effectType => throw _privateConstructorUsedError;
  String get stickerId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            double msgWidth,
            double rotation,
            BigInt sai,
            double scale,
            bool? update,
            BigInt sli,
            double normalizedX,
            double normalizedY,
            BigInt version,
            String hash,
            BigInt safi,
            int effectType,
            String stickerId)
        sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            double msgWidth,
            double rotation,
            BigInt sai,
            double scale,
            bool? update,
            BigInt sli,
            double normalizedX,
            double normalizedY,
            BigInt version,
            String hash,
            BigInt safi,
            int effectType,
            String stickerId)?
        sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            double msgWidth,
            double rotation,
            BigInt sai,
            double scale,
            bool? update,
            BigInt sli,
            double normalizedX,
            double normalizedY,
            BigInt version,
            String hash,
            BigInt safi,
            int effectType,
            String stickerId)?
        sticker,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PartExtension_Sticker value) sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PartExtension_Sticker value)? sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PartExtension_Sticker value)? sticker,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of PartExtension
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartExtensionCopyWith<PartExtension> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartExtensionCopyWith<$Res> {
  factory $PartExtensionCopyWith(
          PartExtension value, $Res Function(PartExtension) then) =
      _$PartExtensionCopyWithImpl<$Res, PartExtension>;
  @useResult
  $Res call(
      {double msgWidth,
      double rotation,
      BigInt sai,
      double scale,
      bool? update,
      BigInt sli,
      double normalizedX,
      double normalizedY,
      BigInt version,
      String hash,
      BigInt safi,
      int effectType,
      String stickerId});
}

/// @nodoc
class _$PartExtensionCopyWithImpl<$Res, $Val extends PartExtension>
    implements $PartExtensionCopyWith<$Res> {
  _$PartExtensionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartExtension
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msgWidth = null,
    Object? rotation = null,
    Object? sai = null,
    Object? scale = null,
    Object? update = freezed,
    Object? sli = null,
    Object? normalizedX = null,
    Object? normalizedY = null,
    Object? version = null,
    Object? hash = null,
    Object? safi = null,
    Object? effectType = null,
    Object? stickerId = null,
  }) {
    return _then(_value.copyWith(
      msgWidth: null == msgWidth
          ? _value.msgWidth
          : msgWidth // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      sai: null == sai
          ? _value.sai
          : sai // ignore: cast_nullable_to_non_nullable
              as BigInt,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      update: freezed == update
          ? _value.update
          : update // ignore: cast_nullable_to_non_nullable
              as bool?,
      sli: null == sli
          ? _value.sli
          : sli // ignore: cast_nullable_to_non_nullable
              as BigInt,
      normalizedX: null == normalizedX
          ? _value.normalizedX
          : normalizedX // ignore: cast_nullable_to_non_nullable
              as double,
      normalizedY: null == normalizedY
          ? _value.normalizedY
          : normalizedY // ignore: cast_nullable_to_non_nullable
              as double,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as BigInt,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      safi: null == safi
          ? _value.safi
          : safi // ignore: cast_nullable_to_non_nullable
              as BigInt,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as int,
      stickerId: null == stickerId
          ? _value.stickerId
          : stickerId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartExtension_StickerImplCopyWith<$Res>
    implements $PartExtensionCopyWith<$Res> {
  factory _$$PartExtension_StickerImplCopyWith(
          _$PartExtension_StickerImpl value,
          $Res Function(_$PartExtension_StickerImpl) then) =
      __$$PartExtension_StickerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double msgWidth,
      double rotation,
      BigInt sai,
      double scale,
      bool? update,
      BigInt sli,
      double normalizedX,
      double normalizedY,
      BigInt version,
      String hash,
      BigInt safi,
      int effectType,
      String stickerId});
}

/// @nodoc
class __$$PartExtension_StickerImplCopyWithImpl<$Res>
    extends _$PartExtensionCopyWithImpl<$Res, _$PartExtension_StickerImpl>
    implements _$$PartExtension_StickerImplCopyWith<$Res> {
  __$$PartExtension_StickerImplCopyWithImpl(_$PartExtension_StickerImpl _value,
      $Res Function(_$PartExtension_StickerImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartExtension
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msgWidth = null,
    Object? rotation = null,
    Object? sai = null,
    Object? scale = null,
    Object? update = freezed,
    Object? sli = null,
    Object? normalizedX = null,
    Object? normalizedY = null,
    Object? version = null,
    Object? hash = null,
    Object? safi = null,
    Object? effectType = null,
    Object? stickerId = null,
  }) {
    return _then(_$PartExtension_StickerImpl(
      msgWidth: null == msgWidth
          ? _value.msgWidth
          : msgWidth // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      sai: null == sai
          ? _value.sai
          : sai // ignore: cast_nullable_to_non_nullable
              as BigInt,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      update: freezed == update
          ? _value.update
          : update // ignore: cast_nullable_to_non_nullable
              as bool?,
      sli: null == sli
          ? _value.sli
          : sli // ignore: cast_nullable_to_non_nullable
              as BigInt,
      normalizedX: null == normalizedX
          ? _value.normalizedX
          : normalizedX // ignore: cast_nullable_to_non_nullable
              as double,
      normalizedY: null == normalizedY
          ? _value.normalizedY
          : normalizedY // ignore: cast_nullable_to_non_nullable
              as double,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as BigInt,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      safi: null == safi
          ? _value.safi
          : safi // ignore: cast_nullable_to_non_nullable
              as BigInt,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as int,
      stickerId: null == stickerId
          ? _value.stickerId
          : stickerId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PartExtension_StickerImpl extends PartExtension_Sticker {
  const _$PartExtension_StickerImpl(
      {required this.msgWidth,
      required this.rotation,
      required this.sai,
      required this.scale,
      this.update,
      required this.sli,
      required this.normalizedX,
      required this.normalizedY,
      required this.version,
      required this.hash,
      required this.safi,
      required this.effectType,
      required this.stickerId})
      : super._();

  @override
  final double msgWidth;
  @override
  final double rotation;
  @override
  final BigInt sai;
  @override
  final double scale;
  @override
  final bool? update;
  @override
  final BigInt sli;
  @override
  final double normalizedX;
  @override
  final double normalizedY;
  @override
  final BigInt version;
  @override
  final String hash;
  @override
  final BigInt safi;
  @override
  final int effectType;
  @override
  final String stickerId;

  @override
  String toString() {
    return 'PartExtension.sticker(msgWidth: $msgWidth, rotation: $rotation, sai: $sai, scale: $scale, update: $update, sli: $sli, normalizedX: $normalizedX, normalizedY: $normalizedY, version: $version, hash: $hash, safi: $safi, effectType: $effectType, stickerId: $stickerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartExtension_StickerImpl &&
            (identical(other.msgWidth, msgWidth) ||
                other.msgWidth == msgWidth) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation) &&
            (identical(other.sai, sai) || other.sai == sai) &&
            (identical(other.scale, scale) || other.scale == scale) &&
            (identical(other.update, update) || other.update == update) &&
            (identical(other.sli, sli) || other.sli == sli) &&
            (identical(other.normalizedX, normalizedX) ||
                other.normalizedX == normalizedX) &&
            (identical(other.normalizedY, normalizedY) ||
                other.normalizedY == normalizedY) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.safi, safi) || other.safi == safi) &&
            (identical(other.effectType, effectType) ||
                other.effectType == effectType) &&
            (identical(other.stickerId, stickerId) ||
                other.stickerId == stickerId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      msgWidth,
      rotation,
      sai,
      scale,
      update,
      sli,
      normalizedX,
      normalizedY,
      version,
      hash,
      safi,
      effectType,
      stickerId);

  /// Create a copy of PartExtension
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartExtension_StickerImplCopyWith<_$PartExtension_StickerImpl>
      get copyWith => __$$PartExtension_StickerImplCopyWithImpl<
          _$PartExtension_StickerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            double msgWidth,
            double rotation,
            BigInt sai,
            double scale,
            bool? update,
            BigInt sli,
            double normalizedX,
            double normalizedY,
            BigInt version,
            String hash,
            BigInt safi,
            int effectType,
            String stickerId)
        sticker,
  }) {
    return sticker(msgWidth, rotation, sai, scale, update, sli, normalizedX,
        normalizedY, version, hash, safi, effectType, stickerId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            double msgWidth,
            double rotation,
            BigInt sai,
            double scale,
            bool? update,
            BigInt sli,
            double normalizedX,
            double normalizedY,
            BigInt version,
            String hash,
            BigInt safi,
            int effectType,
            String stickerId)?
        sticker,
  }) {
    return sticker?.call(msgWidth, rotation, sai, scale, update, sli,
        normalizedX, normalizedY, version, hash, safi, effectType, stickerId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            double msgWidth,
            double rotation,
            BigInt sai,
            double scale,
            bool? update,
            BigInt sli,
            double normalizedX,
            double normalizedY,
            BigInt version,
            String hash,
            BigInt safi,
            int effectType,
            String stickerId)?
        sticker,
    required TResult orElse(),
  }) {
    if (sticker != null) {
      return sticker(msgWidth, rotation, sai, scale, update, sli, normalizedX,
          normalizedY, version, hash, safi, effectType, stickerId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PartExtension_Sticker value) sticker,
  }) {
    return sticker(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PartExtension_Sticker value)? sticker,
  }) {
    return sticker?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PartExtension_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (sticker != null) {
      return sticker(this);
    }
    return orElse();
  }
}

abstract class PartExtension_Sticker extends PartExtension {
  const factory PartExtension_Sticker(
      {required final double msgWidth,
      required final double rotation,
      required final BigInt sai,
      required final double scale,
      final bool? update,
      required final BigInt sli,
      required final double normalizedX,
      required final double normalizedY,
      required final BigInt version,
      required final String hash,
      required final BigInt safi,
      required final int effectType,
      required final String stickerId}) = _$PartExtension_StickerImpl;
  const PartExtension_Sticker._() : super._();

  @override
  double get msgWidth;
  @override
  double get rotation;
  @override
  BigInt get sai;
  @override
  double get scale;
  @override
  bool? get update;
  @override
  BigInt get sli;
  @override
  double get normalizedX;
  @override
  double get normalizedY;
  @override
  BigInt get version;
  @override
  String get hash;
  @override
  BigInt get safi;
  @override
  int get effectType;
  @override
  String get stickerId;

  /// Create a copy of PartExtension
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartExtension_StickerImplCopyWith<_$PartExtension_StickerImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PollResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() stop,
    required TResult Function(PushMessage? field0) cont,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? stop,
    TResult? Function(PushMessage? field0)? cont,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? stop,
    TResult Function(PushMessage? field0)? cont,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PollResult_Stop value) stop,
    required TResult Function(PollResult_Cont value) cont,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PollResult_Stop value)? stop,
    TResult? Function(PollResult_Cont value)? cont,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PollResult_Stop value)? stop,
    TResult Function(PollResult_Cont value)? cont,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollResultCopyWith<$Res> {
  factory $PollResultCopyWith(
          PollResult value, $Res Function(PollResult) then) =
      _$PollResultCopyWithImpl<$Res, PollResult>;
}

/// @nodoc
class _$PollResultCopyWithImpl<$Res, $Val extends PollResult>
    implements $PollResultCopyWith<$Res> {
  _$PollResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PollResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PollResult_StopImplCopyWith<$Res> {
  factory _$$PollResult_StopImplCopyWith(_$PollResult_StopImpl value,
          $Res Function(_$PollResult_StopImpl) then) =
      __$$PollResult_StopImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PollResult_StopImplCopyWithImpl<$Res>
    extends _$PollResultCopyWithImpl<$Res, _$PollResult_StopImpl>
    implements _$$PollResult_StopImplCopyWith<$Res> {
  __$$PollResult_StopImplCopyWithImpl(
      _$PollResult_StopImpl _value, $Res Function(_$PollResult_StopImpl) _then)
      : super(_value, _then);

  /// Create a copy of PollResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PollResult_StopImpl extends PollResult_Stop {
  const _$PollResult_StopImpl() : super._();

  @override
  String toString() {
    return 'PollResult.stop()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PollResult_StopImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() stop,
    required TResult Function(PushMessage? field0) cont,
  }) {
    return stop();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? stop,
    TResult? Function(PushMessage? field0)? cont,
  }) {
    return stop?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? stop,
    TResult Function(PushMessage? field0)? cont,
    required TResult orElse(),
  }) {
    if (stop != null) {
      return stop();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PollResult_Stop value) stop,
    required TResult Function(PollResult_Cont value) cont,
  }) {
    return stop(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PollResult_Stop value)? stop,
    TResult? Function(PollResult_Cont value)? cont,
  }) {
    return stop?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PollResult_Stop value)? stop,
    TResult Function(PollResult_Cont value)? cont,
    required TResult orElse(),
  }) {
    if (stop != null) {
      return stop(this);
    }
    return orElse();
  }
}

abstract class PollResult_Stop extends PollResult {
  const factory PollResult_Stop() = _$PollResult_StopImpl;
  const PollResult_Stop._() : super._();
}

/// @nodoc
abstract class _$$PollResult_ContImplCopyWith<$Res> {
  factory _$$PollResult_ContImplCopyWith(_$PollResult_ContImpl value,
          $Res Function(_$PollResult_ContImpl) then) =
      __$$PollResult_ContImplCopyWithImpl<$Res>;
  @useResult
  $Res call({PushMessage? field0});

  $PushMessageCopyWith<$Res>? get field0;
}

/// @nodoc
class __$$PollResult_ContImplCopyWithImpl<$Res>
    extends _$PollResultCopyWithImpl<$Res, _$PollResult_ContImpl>
    implements _$$PollResult_ContImplCopyWith<$Res> {
  __$$PollResult_ContImplCopyWithImpl(
      _$PollResult_ContImpl _value, $Res Function(_$PollResult_ContImpl) _then)
      : super(_value, _then);

  /// Create a copy of PollResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = freezed,
  }) {
    return _then(_$PollResult_ContImpl(
      freezed == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as PushMessage?,
    ));
  }

  /// Create a copy of PollResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PushMessageCopyWith<$Res>? get field0 {
    if (_value.field0 == null) {
      return null;
    }

    return $PushMessageCopyWith<$Res>(_value.field0!, (value) {
      return _then(_value.copyWith(field0: value));
    });
  }
}

/// @nodoc

class _$PollResult_ContImpl extends PollResult_Cont {
  const _$PollResult_ContImpl([this.field0]) : super._();

  @override
  final PushMessage? field0;

  @override
  String toString() {
    return 'PollResult.cont(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PollResult_ContImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of PollResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PollResult_ContImplCopyWith<_$PollResult_ContImpl> get copyWith =>
      __$$PollResult_ContImplCopyWithImpl<_$PollResult_ContImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() stop,
    required TResult Function(PushMessage? field0) cont,
  }) {
    return cont(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? stop,
    TResult? Function(PushMessage? field0)? cont,
  }) {
    return cont?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? stop,
    TResult Function(PushMessage? field0)? cont,
    required TResult orElse(),
  }) {
    if (cont != null) {
      return cont(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PollResult_Stop value) stop,
    required TResult Function(PollResult_Cont value) cont,
  }) {
    return cont(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PollResult_Stop value)? stop,
    TResult? Function(PollResult_Cont value)? cont,
  }) {
    return cont?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PollResult_Stop value)? stop,
    TResult Function(PollResult_Cont value)? cont,
    required TResult orElse(),
  }) {
    if (cont != null) {
      return cont(this);
    }
    return orElse();
  }
}

abstract class PollResult_Cont extends PollResult {
  const factory PollResult_Cont([final PushMessage? field0]) =
      _$PollResult_ContImpl;
  const PollResult_Cont._() : super._();

  PushMessage? get field0;

  /// Create a copy of PollResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PollResult_ContImplCopyWith<_$PollResult_ContImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PushMessage {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageInst field0) iMessage,
    required TResult Function(String uuid, String? error) sendConfirm,
    required TResult Function(RegisterState field0) registrationState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageInst field0)? iMessage,
    TResult? Function(String uuid, String? error)? sendConfirm,
    TResult? Function(RegisterState field0)? registrationState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageInst field0)? iMessage,
    TResult Function(String uuid, String? error)? sendConfirm,
    TResult Function(RegisterState field0)? registrationState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PushMessage_IMessage value) iMessage,
    required TResult Function(PushMessage_SendConfirm value) sendConfirm,
    required TResult Function(PushMessage_RegistrationState value)
        registrationState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PushMessage_IMessage value)? iMessage,
    TResult? Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult? Function(PushMessage_RegistrationState value)? registrationState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PushMessage_IMessage value)? iMessage,
    TResult Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult Function(PushMessage_RegistrationState value)? registrationState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PushMessageCopyWith<$Res> {
  factory $PushMessageCopyWith(
          PushMessage value, $Res Function(PushMessage) then) =
      _$PushMessageCopyWithImpl<$Res, PushMessage>;
}

/// @nodoc
class _$PushMessageCopyWithImpl<$Res, $Val extends PushMessage>
    implements $PushMessageCopyWith<$Res> {
  _$PushMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PushMessage_IMessageImplCopyWith<$Res> {
  factory _$$PushMessage_IMessageImplCopyWith(_$PushMessage_IMessageImpl value,
          $Res Function(_$PushMessage_IMessageImpl) then) =
      __$$PushMessage_IMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MessageInst field0});
}

/// @nodoc
class __$$PushMessage_IMessageImplCopyWithImpl<$Res>
    extends _$PushMessageCopyWithImpl<$Res, _$PushMessage_IMessageImpl>
    implements _$$PushMessage_IMessageImplCopyWith<$Res> {
  __$$PushMessage_IMessageImplCopyWithImpl(_$PushMessage_IMessageImpl _value,
      $Res Function(_$PushMessage_IMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$PushMessage_IMessageImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MessageInst,
    ));
  }
}

/// @nodoc

class _$PushMessage_IMessageImpl extends PushMessage_IMessage {
  const _$PushMessage_IMessageImpl(this.field0) : super._();

  @override
  final MessageInst field0;

  @override
  String toString() {
    return 'PushMessage.iMessage(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PushMessage_IMessageImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PushMessage_IMessageImplCopyWith<_$PushMessage_IMessageImpl>
      get copyWith =>
          __$$PushMessage_IMessageImplCopyWithImpl<_$PushMessage_IMessageImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageInst field0) iMessage,
    required TResult Function(String uuid, String? error) sendConfirm,
    required TResult Function(RegisterState field0) registrationState,
  }) {
    return iMessage(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageInst field0)? iMessage,
    TResult? Function(String uuid, String? error)? sendConfirm,
    TResult? Function(RegisterState field0)? registrationState,
  }) {
    return iMessage?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageInst field0)? iMessage,
    TResult Function(String uuid, String? error)? sendConfirm,
    TResult Function(RegisterState field0)? registrationState,
    required TResult orElse(),
  }) {
    if (iMessage != null) {
      return iMessage(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PushMessage_IMessage value) iMessage,
    required TResult Function(PushMessage_SendConfirm value) sendConfirm,
    required TResult Function(PushMessage_RegistrationState value)
        registrationState,
  }) {
    return iMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PushMessage_IMessage value)? iMessage,
    TResult? Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult? Function(PushMessage_RegistrationState value)? registrationState,
  }) {
    return iMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PushMessage_IMessage value)? iMessage,
    TResult Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult Function(PushMessage_RegistrationState value)? registrationState,
    required TResult orElse(),
  }) {
    if (iMessage != null) {
      return iMessage(this);
    }
    return orElse();
  }
}

abstract class PushMessage_IMessage extends PushMessage {
  const factory PushMessage_IMessage(final MessageInst field0) =
      _$PushMessage_IMessageImpl;
  const PushMessage_IMessage._() : super._();

  MessageInst get field0;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PushMessage_IMessageImplCopyWith<_$PushMessage_IMessageImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PushMessage_SendConfirmImplCopyWith<$Res> {
  factory _$$PushMessage_SendConfirmImplCopyWith(
          _$PushMessage_SendConfirmImpl value,
          $Res Function(_$PushMessage_SendConfirmImpl) then) =
      __$$PushMessage_SendConfirmImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String uuid, String? error});
}

/// @nodoc
class __$$PushMessage_SendConfirmImplCopyWithImpl<$Res>
    extends _$PushMessageCopyWithImpl<$Res, _$PushMessage_SendConfirmImpl>
    implements _$$PushMessage_SendConfirmImplCopyWith<$Res> {
  __$$PushMessage_SendConfirmImplCopyWithImpl(
      _$PushMessage_SendConfirmImpl _value,
      $Res Function(_$PushMessage_SendConfirmImpl) _then)
      : super(_value, _then);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? error = freezed,
  }) {
    return _then(_$PushMessage_SendConfirmImpl(
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PushMessage_SendConfirmImpl extends PushMessage_SendConfirm {
  const _$PushMessage_SendConfirmImpl({required this.uuid, this.error})
      : super._();

  @override
  final String uuid;
  @override
  final String? error;

  @override
  String toString() {
    return 'PushMessage.sendConfirm(uuid: $uuid, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PushMessage_SendConfirmImpl &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, uuid, error);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PushMessage_SendConfirmImplCopyWith<_$PushMessage_SendConfirmImpl>
      get copyWith => __$$PushMessage_SendConfirmImplCopyWithImpl<
          _$PushMessage_SendConfirmImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageInst field0) iMessage,
    required TResult Function(String uuid, String? error) sendConfirm,
    required TResult Function(RegisterState field0) registrationState,
  }) {
    return sendConfirm(uuid, error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageInst field0)? iMessage,
    TResult? Function(String uuid, String? error)? sendConfirm,
    TResult? Function(RegisterState field0)? registrationState,
  }) {
    return sendConfirm?.call(uuid, error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageInst field0)? iMessage,
    TResult Function(String uuid, String? error)? sendConfirm,
    TResult Function(RegisterState field0)? registrationState,
    required TResult orElse(),
  }) {
    if (sendConfirm != null) {
      return sendConfirm(uuid, error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PushMessage_IMessage value) iMessage,
    required TResult Function(PushMessage_SendConfirm value) sendConfirm,
    required TResult Function(PushMessage_RegistrationState value)
        registrationState,
  }) {
    return sendConfirm(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PushMessage_IMessage value)? iMessage,
    TResult? Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult? Function(PushMessage_RegistrationState value)? registrationState,
  }) {
    return sendConfirm?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PushMessage_IMessage value)? iMessage,
    TResult Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult Function(PushMessage_RegistrationState value)? registrationState,
    required TResult orElse(),
  }) {
    if (sendConfirm != null) {
      return sendConfirm(this);
    }
    return orElse();
  }
}

abstract class PushMessage_SendConfirm extends PushMessage {
  const factory PushMessage_SendConfirm(
      {required final String uuid,
      final String? error}) = _$PushMessage_SendConfirmImpl;
  const PushMessage_SendConfirm._() : super._();

  String get uuid;
  String? get error;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PushMessage_SendConfirmImplCopyWith<_$PushMessage_SendConfirmImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PushMessage_RegistrationStateImplCopyWith<$Res> {
  factory _$$PushMessage_RegistrationStateImplCopyWith(
          _$PushMessage_RegistrationStateImpl value,
          $Res Function(_$PushMessage_RegistrationStateImpl) then) =
      __$$PushMessage_RegistrationStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({RegisterState field0});

  $RegisterStateCopyWith<$Res> get field0;
}

/// @nodoc
class __$$PushMessage_RegistrationStateImplCopyWithImpl<$Res>
    extends _$PushMessageCopyWithImpl<$Res, _$PushMessage_RegistrationStateImpl>
    implements _$$PushMessage_RegistrationStateImplCopyWith<$Res> {
  __$$PushMessage_RegistrationStateImplCopyWithImpl(
      _$PushMessage_RegistrationStateImpl _value,
      $Res Function(_$PushMessage_RegistrationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$PushMessage_RegistrationStateImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as RegisterState,
    ));
  }

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RegisterStateCopyWith<$Res> get field0 {
    return $RegisterStateCopyWith<$Res>(_value.field0, (value) {
      return _then(_value.copyWith(field0: value));
    });
  }
}

/// @nodoc

class _$PushMessage_RegistrationStateImpl
    extends PushMessage_RegistrationState {
  const _$PushMessage_RegistrationStateImpl(this.field0) : super._();

  @override
  final RegisterState field0;

  @override
  String toString() {
    return 'PushMessage.registrationState(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PushMessage_RegistrationStateImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PushMessage_RegistrationStateImplCopyWith<
          _$PushMessage_RegistrationStateImpl>
      get copyWith => __$$PushMessage_RegistrationStateImplCopyWithImpl<
          _$PushMessage_RegistrationStateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageInst field0) iMessage,
    required TResult Function(String uuid, String? error) sendConfirm,
    required TResult Function(RegisterState field0) registrationState,
  }) {
    return registrationState(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageInst field0)? iMessage,
    TResult? Function(String uuid, String? error)? sendConfirm,
    TResult? Function(RegisterState field0)? registrationState,
  }) {
    return registrationState?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageInst field0)? iMessage,
    TResult Function(String uuid, String? error)? sendConfirm,
    TResult Function(RegisterState field0)? registrationState,
    required TResult orElse(),
  }) {
    if (registrationState != null) {
      return registrationState(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PushMessage_IMessage value) iMessage,
    required TResult Function(PushMessage_SendConfirm value) sendConfirm,
    required TResult Function(PushMessage_RegistrationState value)
        registrationState,
  }) {
    return registrationState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PushMessage_IMessage value)? iMessage,
    TResult? Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult? Function(PushMessage_RegistrationState value)? registrationState,
  }) {
    return registrationState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PushMessage_IMessage value)? iMessage,
    TResult Function(PushMessage_SendConfirm value)? sendConfirm,
    TResult Function(PushMessage_RegistrationState value)? registrationState,
    required TResult orElse(),
  }) {
    if (registrationState != null) {
      return registrationState(this);
    }
    return orElse();
  }
}

abstract class PushMessage_RegistrationState extends PushMessage {
  const factory PushMessage_RegistrationState(final RegisterState field0) =
      _$PushMessage_RegistrationStateImpl;
  const PushMessage_RegistrationState._() : super._();

  RegisterState get field0;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PushMessage_RegistrationStateImplCopyWith<
          _$PushMessage_RegistrationStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ReactMessageType {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Reaction reaction, bool enable) react,
    required TResult Function(ExtensionApp spec, MessageParts body) extension_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Reaction reaction, bool enable)? react,
    TResult? Function(ExtensionApp spec, MessageParts body)? extension_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Reaction reaction, bool enable)? react,
    TResult Function(ExtensionApp spec, MessageParts body)? extension_,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReactMessageType_React value) react,
    required TResult Function(ReactMessageType_Extension value) extension_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReactMessageType_React value)? react,
    TResult? Function(ReactMessageType_Extension value)? extension_,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReactMessageType_React value)? react,
    TResult Function(ReactMessageType_Extension value)? extension_,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReactMessageTypeCopyWith<$Res> {
  factory $ReactMessageTypeCopyWith(
          ReactMessageType value, $Res Function(ReactMessageType) then) =
      _$ReactMessageTypeCopyWithImpl<$Res, ReactMessageType>;
}

/// @nodoc
class _$ReactMessageTypeCopyWithImpl<$Res, $Val extends ReactMessageType>
    implements $ReactMessageTypeCopyWith<$Res> {
  _$ReactMessageTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ReactMessageType_ReactImplCopyWith<$Res> {
  factory _$$ReactMessageType_ReactImplCopyWith(
          _$ReactMessageType_ReactImpl value,
          $Res Function(_$ReactMessageType_ReactImpl) then) =
      __$$ReactMessageType_ReactImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Reaction reaction, bool enable});

  $ReactionCopyWith<$Res> get reaction;
}

/// @nodoc
class __$$ReactMessageType_ReactImplCopyWithImpl<$Res>
    extends _$ReactMessageTypeCopyWithImpl<$Res, _$ReactMessageType_ReactImpl>
    implements _$$ReactMessageType_ReactImplCopyWith<$Res> {
  __$$ReactMessageType_ReactImplCopyWithImpl(
      _$ReactMessageType_ReactImpl _value,
      $Res Function(_$ReactMessageType_ReactImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reaction = null,
    Object? enable = null,
  }) {
    return _then(_$ReactMessageType_ReactImpl(
      reaction: null == reaction
          ? _value.reaction
          : reaction // ignore: cast_nullable_to_non_nullable
              as Reaction,
      enable: null == enable
          ? _value.enable
          : enable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReactionCopyWith<$Res> get reaction {
    return $ReactionCopyWith<$Res>(_value.reaction, (value) {
      return _then(_value.copyWith(reaction: value));
    });
  }
}

/// @nodoc

class _$ReactMessageType_ReactImpl extends ReactMessageType_React {
  const _$ReactMessageType_ReactImpl(
      {required this.reaction, required this.enable})
      : super._();

  @override
  final Reaction reaction;
  @override
  final bool enable;

  @override
  String toString() {
    return 'ReactMessageType.react(reaction: $reaction, enable: $enable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReactMessageType_ReactImpl &&
            (identical(other.reaction, reaction) ||
                other.reaction == reaction) &&
            (identical(other.enable, enable) || other.enable == enable));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reaction, enable);

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReactMessageType_ReactImplCopyWith<_$ReactMessageType_ReactImpl>
      get copyWith => __$$ReactMessageType_ReactImplCopyWithImpl<
          _$ReactMessageType_ReactImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Reaction reaction, bool enable) react,
    required TResult Function(ExtensionApp spec, MessageParts body) extension_,
  }) {
    return react(reaction, enable);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Reaction reaction, bool enable)? react,
    TResult? Function(ExtensionApp spec, MessageParts body)? extension_,
  }) {
    return react?.call(reaction, enable);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Reaction reaction, bool enable)? react,
    TResult Function(ExtensionApp spec, MessageParts body)? extension_,
    required TResult orElse(),
  }) {
    if (react != null) {
      return react(reaction, enable);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReactMessageType_React value) react,
    required TResult Function(ReactMessageType_Extension value) extension_,
  }) {
    return react(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReactMessageType_React value)? react,
    TResult? Function(ReactMessageType_Extension value)? extension_,
  }) {
    return react?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReactMessageType_React value)? react,
    TResult Function(ReactMessageType_Extension value)? extension_,
    required TResult orElse(),
  }) {
    if (react != null) {
      return react(this);
    }
    return orElse();
  }
}

abstract class ReactMessageType_React extends ReactMessageType {
  const factory ReactMessageType_React(
      {required final Reaction reaction,
      required final bool enable}) = _$ReactMessageType_ReactImpl;
  const ReactMessageType_React._() : super._();

  Reaction get reaction;
  bool get enable;

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReactMessageType_ReactImplCopyWith<_$ReactMessageType_ReactImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReactMessageType_ExtensionImplCopyWith<$Res> {
  factory _$$ReactMessageType_ExtensionImplCopyWith(
          _$ReactMessageType_ExtensionImpl value,
          $Res Function(_$ReactMessageType_ExtensionImpl) then) =
      __$$ReactMessageType_ExtensionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ExtensionApp spec, MessageParts body});
}

/// @nodoc
class __$$ReactMessageType_ExtensionImplCopyWithImpl<$Res>
    extends _$ReactMessageTypeCopyWithImpl<$Res,
        _$ReactMessageType_ExtensionImpl>
    implements _$$ReactMessageType_ExtensionImplCopyWith<$Res> {
  __$$ReactMessageType_ExtensionImplCopyWithImpl(
      _$ReactMessageType_ExtensionImpl _value,
      $Res Function(_$ReactMessageType_ExtensionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spec = null,
    Object? body = null,
  }) {
    return _then(_$ReactMessageType_ExtensionImpl(
      spec: null == spec
          ? _value.spec
          : spec // ignore: cast_nullable_to_non_nullable
              as ExtensionApp,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as MessageParts,
    ));
  }
}

/// @nodoc

class _$ReactMessageType_ExtensionImpl extends ReactMessageType_Extension {
  const _$ReactMessageType_ExtensionImpl(
      {required this.spec, required this.body})
      : super._();

  @override
  final ExtensionApp spec;
  @override
  final MessageParts body;

  @override
  String toString() {
    return 'ReactMessageType.extension_(spec: $spec, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReactMessageType_ExtensionImpl &&
            (identical(other.spec, spec) || other.spec == spec) &&
            (identical(other.body, body) || other.body == body));
  }

  @override
  int get hashCode => Object.hash(runtimeType, spec, body);

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReactMessageType_ExtensionImplCopyWith<_$ReactMessageType_ExtensionImpl>
      get copyWith => __$$ReactMessageType_ExtensionImplCopyWithImpl<
          _$ReactMessageType_ExtensionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Reaction reaction, bool enable) react,
    required TResult Function(ExtensionApp spec, MessageParts body) extension_,
  }) {
    return extension_(spec, body);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Reaction reaction, bool enable)? react,
    TResult? Function(ExtensionApp spec, MessageParts body)? extension_,
  }) {
    return extension_?.call(spec, body);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Reaction reaction, bool enable)? react,
    TResult Function(ExtensionApp spec, MessageParts body)? extension_,
    required TResult orElse(),
  }) {
    if (extension_ != null) {
      return extension_(spec, body);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReactMessageType_React value) react,
    required TResult Function(ReactMessageType_Extension value) extension_,
  }) {
    return extension_(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReactMessageType_React value)? react,
    TResult? Function(ReactMessageType_Extension value)? extension_,
  }) {
    return extension_?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReactMessageType_React value)? react,
    TResult Function(ReactMessageType_Extension value)? extension_,
    required TResult orElse(),
  }) {
    if (extension_ != null) {
      return extension_(this);
    }
    return orElse();
  }
}

abstract class ReactMessageType_Extension extends ReactMessageType {
  const factory ReactMessageType_Extension(
      {required final ExtensionApp spec,
      required final MessageParts body}) = _$ReactMessageType_ExtensionImpl;
  const ReactMessageType_Extension._() : super._();

  ExtensionApp get spec;
  MessageParts get body;

  /// Create a copy of ReactMessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReactMessageType_ExtensionImplCopyWith<_$ReactMessageType_ExtensionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Reaction {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReactionCopyWith<$Res> {
  factory $ReactionCopyWith(Reaction value, $Res Function(Reaction) then) =
      _$ReactionCopyWithImpl<$Res, Reaction>;
}

/// @nodoc
class _$ReactionCopyWithImpl<$Res, $Val extends Reaction>
    implements $ReactionCopyWith<$Res> {
  _$ReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Reaction_HeartImplCopyWith<$Res> {
  factory _$$Reaction_HeartImplCopyWith(_$Reaction_HeartImpl value,
          $Res Function(_$Reaction_HeartImpl) then) =
      __$$Reaction_HeartImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Reaction_HeartImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_HeartImpl>
    implements _$$Reaction_HeartImplCopyWith<$Res> {
  __$$Reaction_HeartImplCopyWithImpl(
      _$Reaction_HeartImpl _value, $Res Function(_$Reaction_HeartImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Reaction_HeartImpl extends Reaction_Heart {
  const _$Reaction_HeartImpl() : super._();

  @override
  String toString() {
    return 'Reaction.heart()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Reaction_HeartImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return heart();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return heart?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (heart != null) {
      return heart();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return heart(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return heart?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (heart != null) {
      return heart(this);
    }
    return orElse();
  }
}

abstract class Reaction_Heart extends Reaction {
  const factory Reaction_Heart() = _$Reaction_HeartImpl;
  const Reaction_Heart._() : super._();
}

/// @nodoc
abstract class _$$Reaction_LikeImplCopyWith<$Res> {
  factory _$$Reaction_LikeImplCopyWith(
          _$Reaction_LikeImpl value, $Res Function(_$Reaction_LikeImpl) then) =
      __$$Reaction_LikeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Reaction_LikeImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_LikeImpl>
    implements _$$Reaction_LikeImplCopyWith<$Res> {
  __$$Reaction_LikeImplCopyWithImpl(
      _$Reaction_LikeImpl _value, $Res Function(_$Reaction_LikeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Reaction_LikeImpl extends Reaction_Like {
  const _$Reaction_LikeImpl() : super._();

  @override
  String toString() {
    return 'Reaction.like()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Reaction_LikeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return like();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return like?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (like != null) {
      return like();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return like(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return like?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (like != null) {
      return like(this);
    }
    return orElse();
  }
}

abstract class Reaction_Like extends Reaction {
  const factory Reaction_Like() = _$Reaction_LikeImpl;
  const Reaction_Like._() : super._();
}

/// @nodoc
abstract class _$$Reaction_DislikeImplCopyWith<$Res> {
  factory _$$Reaction_DislikeImplCopyWith(_$Reaction_DislikeImpl value,
          $Res Function(_$Reaction_DislikeImpl) then) =
      __$$Reaction_DislikeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Reaction_DislikeImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_DislikeImpl>
    implements _$$Reaction_DislikeImplCopyWith<$Res> {
  __$$Reaction_DislikeImplCopyWithImpl(_$Reaction_DislikeImpl _value,
      $Res Function(_$Reaction_DislikeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Reaction_DislikeImpl extends Reaction_Dislike {
  const _$Reaction_DislikeImpl() : super._();

  @override
  String toString() {
    return 'Reaction.dislike()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Reaction_DislikeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return dislike();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return dislike?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (dislike != null) {
      return dislike();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return dislike(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return dislike?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (dislike != null) {
      return dislike(this);
    }
    return orElse();
  }
}

abstract class Reaction_Dislike extends Reaction {
  const factory Reaction_Dislike() = _$Reaction_DislikeImpl;
  const Reaction_Dislike._() : super._();
}

/// @nodoc
abstract class _$$Reaction_LaughImplCopyWith<$Res> {
  factory _$$Reaction_LaughImplCopyWith(_$Reaction_LaughImpl value,
          $Res Function(_$Reaction_LaughImpl) then) =
      __$$Reaction_LaughImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Reaction_LaughImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_LaughImpl>
    implements _$$Reaction_LaughImplCopyWith<$Res> {
  __$$Reaction_LaughImplCopyWithImpl(
      _$Reaction_LaughImpl _value, $Res Function(_$Reaction_LaughImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Reaction_LaughImpl extends Reaction_Laugh {
  const _$Reaction_LaughImpl() : super._();

  @override
  String toString() {
    return 'Reaction.laugh()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Reaction_LaughImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return laugh();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return laugh?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (laugh != null) {
      return laugh();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return laugh(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return laugh?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (laugh != null) {
      return laugh(this);
    }
    return orElse();
  }
}

abstract class Reaction_Laugh extends Reaction {
  const factory Reaction_Laugh() = _$Reaction_LaughImpl;
  const Reaction_Laugh._() : super._();
}

/// @nodoc
abstract class _$$Reaction_EmphasizeImplCopyWith<$Res> {
  factory _$$Reaction_EmphasizeImplCopyWith(_$Reaction_EmphasizeImpl value,
          $Res Function(_$Reaction_EmphasizeImpl) then) =
      __$$Reaction_EmphasizeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Reaction_EmphasizeImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_EmphasizeImpl>
    implements _$$Reaction_EmphasizeImplCopyWith<$Res> {
  __$$Reaction_EmphasizeImplCopyWithImpl(_$Reaction_EmphasizeImpl _value,
      $Res Function(_$Reaction_EmphasizeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Reaction_EmphasizeImpl extends Reaction_Emphasize {
  const _$Reaction_EmphasizeImpl() : super._();

  @override
  String toString() {
    return 'Reaction.emphasize()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Reaction_EmphasizeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return emphasize();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return emphasize?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (emphasize != null) {
      return emphasize();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return emphasize(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return emphasize?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (emphasize != null) {
      return emphasize(this);
    }
    return orElse();
  }
}

abstract class Reaction_Emphasize extends Reaction {
  const factory Reaction_Emphasize() = _$Reaction_EmphasizeImpl;
  const Reaction_Emphasize._() : super._();
}

/// @nodoc
abstract class _$$Reaction_QuestionImplCopyWith<$Res> {
  factory _$$Reaction_QuestionImplCopyWith(_$Reaction_QuestionImpl value,
          $Res Function(_$Reaction_QuestionImpl) then) =
      __$$Reaction_QuestionImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Reaction_QuestionImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_QuestionImpl>
    implements _$$Reaction_QuestionImplCopyWith<$Res> {
  __$$Reaction_QuestionImplCopyWithImpl(_$Reaction_QuestionImpl _value,
      $Res Function(_$Reaction_QuestionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Reaction_QuestionImpl extends Reaction_Question {
  const _$Reaction_QuestionImpl() : super._();

  @override
  String toString() {
    return 'Reaction.question()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Reaction_QuestionImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return question();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return question?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (question != null) {
      return question();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return question(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return question?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (question != null) {
      return question(this);
    }
    return orElse();
  }
}

abstract class Reaction_Question extends Reaction {
  const factory Reaction_Question() = _$Reaction_QuestionImpl;
  const Reaction_Question._() : super._();
}

/// @nodoc
abstract class _$$Reaction_EmojiImplCopyWith<$Res> {
  factory _$$Reaction_EmojiImplCopyWith(_$Reaction_EmojiImpl value,
          $Res Function(_$Reaction_EmojiImpl) then) =
      __$$Reaction_EmojiImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$Reaction_EmojiImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_EmojiImpl>
    implements _$$Reaction_EmojiImplCopyWith<$Res> {
  __$$Reaction_EmojiImplCopyWithImpl(
      _$Reaction_EmojiImpl _value, $Res Function(_$Reaction_EmojiImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$Reaction_EmojiImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Reaction_EmojiImpl extends Reaction_Emoji {
  const _$Reaction_EmojiImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'Reaction.emoji(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Reaction_EmojiImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Reaction_EmojiImplCopyWith<_$Reaction_EmojiImpl> get copyWith =>
      __$$Reaction_EmojiImplCopyWithImpl<_$Reaction_EmojiImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return emoji(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return emoji?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (emoji != null) {
      return emoji(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return emoji(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return emoji?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (emoji != null) {
      return emoji(this);
    }
    return orElse();
  }
}

abstract class Reaction_Emoji extends Reaction {
  const factory Reaction_Emoji(final String field0) = _$Reaction_EmojiImpl;
  const Reaction_Emoji._() : super._();

  String get field0;

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Reaction_EmojiImplCopyWith<_$Reaction_EmojiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Reaction_StickerImplCopyWith<$Res> {
  factory _$$Reaction_StickerImplCopyWith(_$Reaction_StickerImpl value,
          $Res Function(_$Reaction_StickerImpl) then) =
      __$$Reaction_StickerImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ExtensionApp? spec, MessageParts body});
}

/// @nodoc
class __$$Reaction_StickerImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$Reaction_StickerImpl>
    implements _$$Reaction_StickerImplCopyWith<$Res> {
  __$$Reaction_StickerImplCopyWithImpl(_$Reaction_StickerImpl _value,
      $Res Function(_$Reaction_StickerImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spec = freezed,
    Object? body = null,
  }) {
    return _then(_$Reaction_StickerImpl(
      spec: freezed == spec
          ? _value.spec
          : spec // ignore: cast_nullable_to_non_nullable
              as ExtensionApp?,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as MessageParts,
    ));
  }
}

/// @nodoc

class _$Reaction_StickerImpl extends Reaction_Sticker {
  const _$Reaction_StickerImpl({this.spec, required this.body}) : super._();

  @override
  final ExtensionApp? spec;
  @override
  final MessageParts body;

  @override
  String toString() {
    return 'Reaction.sticker(spec: $spec, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Reaction_StickerImpl &&
            (identical(other.spec, spec) || other.spec == spec) &&
            (identical(other.body, body) || other.body == body));
  }

  @override
  int get hashCode => Object.hash(runtimeType, spec, body);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Reaction_StickerImplCopyWith<_$Reaction_StickerImpl> get copyWith =>
      __$$Reaction_StickerImplCopyWithImpl<_$Reaction_StickerImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() heart,
    required TResult Function() like,
    required TResult Function() dislike,
    required TResult Function() laugh,
    required TResult Function() emphasize,
    required TResult Function() question,
    required TResult Function(String field0) emoji,
    required TResult Function(ExtensionApp? spec, MessageParts body) sticker,
  }) {
    return sticker(spec, body);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? heart,
    TResult? Function()? like,
    TResult? Function()? dislike,
    TResult? Function()? laugh,
    TResult? Function()? emphasize,
    TResult? Function()? question,
    TResult? Function(String field0)? emoji,
    TResult? Function(ExtensionApp? spec, MessageParts body)? sticker,
  }) {
    return sticker?.call(spec, body);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? heart,
    TResult Function()? like,
    TResult Function()? dislike,
    TResult Function()? laugh,
    TResult Function()? emphasize,
    TResult Function()? question,
    TResult Function(String field0)? emoji,
    TResult Function(ExtensionApp? spec, MessageParts body)? sticker,
    required TResult orElse(),
  }) {
    if (sticker != null) {
      return sticker(spec, body);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Reaction_Heart value) heart,
    required TResult Function(Reaction_Like value) like,
    required TResult Function(Reaction_Dislike value) dislike,
    required TResult Function(Reaction_Laugh value) laugh,
    required TResult Function(Reaction_Emphasize value) emphasize,
    required TResult Function(Reaction_Question value) question,
    required TResult Function(Reaction_Emoji value) emoji,
    required TResult Function(Reaction_Sticker value) sticker,
  }) {
    return sticker(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Reaction_Heart value)? heart,
    TResult? Function(Reaction_Like value)? like,
    TResult? Function(Reaction_Dislike value)? dislike,
    TResult? Function(Reaction_Laugh value)? laugh,
    TResult? Function(Reaction_Emphasize value)? emphasize,
    TResult? Function(Reaction_Question value)? question,
    TResult? Function(Reaction_Emoji value)? emoji,
    TResult? Function(Reaction_Sticker value)? sticker,
  }) {
    return sticker?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Reaction_Heart value)? heart,
    TResult Function(Reaction_Like value)? like,
    TResult Function(Reaction_Dislike value)? dislike,
    TResult Function(Reaction_Laugh value)? laugh,
    TResult Function(Reaction_Emphasize value)? emphasize,
    TResult Function(Reaction_Question value)? question,
    TResult Function(Reaction_Emoji value)? emoji,
    TResult Function(Reaction_Sticker value)? sticker,
    required TResult orElse(),
  }) {
    if (sticker != null) {
      return sticker(this);
    }
    return orElse();
  }
}

abstract class Reaction_Sticker extends Reaction {
  const factory Reaction_Sticker(
      {final ExtensionApp? spec,
      required final MessageParts body}) = _$Reaction_StickerImpl;
  const Reaction_Sticker._() : super._();

  ExtensionApp? get spec;
  MessageParts get body;

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Reaction_StickerImplCopyWith<_$Reaction_StickerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RegisterState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int nextS) registered,
    required TResult Function() registering,
    required TResult Function(BigInt? retryWait, String error) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int nextS)? registered,
    TResult? Function()? registering,
    TResult? Function(BigInt? retryWait, String error)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int nextS)? registered,
    TResult Function()? registering,
    TResult Function(BigInt? retryWait, String error)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RegisterState_Registered value) registered,
    required TResult Function(RegisterState_Registering value) registering,
    required TResult Function(RegisterState_Failed value) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RegisterState_Registered value)? registered,
    TResult? Function(RegisterState_Registering value)? registering,
    TResult? Function(RegisterState_Failed value)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RegisterState_Registered value)? registered,
    TResult Function(RegisterState_Registering value)? registering,
    TResult Function(RegisterState_Failed value)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegisterStateCopyWith<$Res> {
  factory $RegisterStateCopyWith(
          RegisterState value, $Res Function(RegisterState) then) =
      _$RegisterStateCopyWithImpl<$Res, RegisterState>;
}

/// @nodoc
class _$RegisterStateCopyWithImpl<$Res, $Val extends RegisterState>
    implements $RegisterStateCopyWith<$Res> {
  _$RegisterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$RegisterState_RegisteredImplCopyWith<$Res> {
  factory _$$RegisterState_RegisteredImplCopyWith(
          _$RegisterState_RegisteredImpl value,
          $Res Function(_$RegisterState_RegisteredImpl) then) =
      __$$RegisterState_RegisteredImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int nextS});
}

/// @nodoc
class __$$RegisterState_RegisteredImplCopyWithImpl<$Res>
    extends _$RegisterStateCopyWithImpl<$Res, _$RegisterState_RegisteredImpl>
    implements _$$RegisterState_RegisteredImplCopyWith<$Res> {
  __$$RegisterState_RegisteredImplCopyWithImpl(
      _$RegisterState_RegisteredImpl _value,
      $Res Function(_$RegisterState_RegisteredImpl) _then)
      : super(_value, _then);

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nextS = null,
  }) {
    return _then(_$RegisterState_RegisteredImpl(
      nextS: null == nextS
          ? _value.nextS
          : nextS // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$RegisterState_RegisteredImpl extends RegisterState_Registered {
  const _$RegisterState_RegisteredImpl({required this.nextS}) : super._();

  @override
  final int nextS;

  @override
  String toString() {
    return 'RegisterState.registered(nextS: $nextS)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterState_RegisteredImpl &&
            (identical(other.nextS, nextS) || other.nextS == nextS));
  }

  @override
  int get hashCode => Object.hash(runtimeType, nextS);

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterState_RegisteredImplCopyWith<_$RegisterState_RegisteredImpl>
      get copyWith => __$$RegisterState_RegisteredImplCopyWithImpl<
          _$RegisterState_RegisteredImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int nextS) registered,
    required TResult Function() registering,
    required TResult Function(BigInt? retryWait, String error) failed,
  }) {
    return registered(nextS);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int nextS)? registered,
    TResult? Function()? registering,
    TResult? Function(BigInt? retryWait, String error)? failed,
  }) {
    return registered?.call(nextS);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int nextS)? registered,
    TResult Function()? registering,
    TResult Function(BigInt? retryWait, String error)? failed,
    required TResult orElse(),
  }) {
    if (registered != null) {
      return registered(nextS);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RegisterState_Registered value) registered,
    required TResult Function(RegisterState_Registering value) registering,
    required TResult Function(RegisterState_Failed value) failed,
  }) {
    return registered(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RegisterState_Registered value)? registered,
    TResult? Function(RegisterState_Registering value)? registering,
    TResult? Function(RegisterState_Failed value)? failed,
  }) {
    return registered?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RegisterState_Registered value)? registered,
    TResult Function(RegisterState_Registering value)? registering,
    TResult Function(RegisterState_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (registered != null) {
      return registered(this);
    }
    return orElse();
  }
}

abstract class RegisterState_Registered extends RegisterState {
  const factory RegisterState_Registered({required final int nextS}) =
      _$RegisterState_RegisteredImpl;
  const RegisterState_Registered._() : super._();

  int get nextS;

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterState_RegisteredImplCopyWith<_$RegisterState_RegisteredImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RegisterState_RegisteringImplCopyWith<$Res> {
  factory _$$RegisterState_RegisteringImplCopyWith(
          _$RegisterState_RegisteringImpl value,
          $Res Function(_$RegisterState_RegisteringImpl) then) =
      __$$RegisterState_RegisteringImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RegisterState_RegisteringImplCopyWithImpl<$Res>
    extends _$RegisterStateCopyWithImpl<$Res, _$RegisterState_RegisteringImpl>
    implements _$$RegisterState_RegisteringImplCopyWith<$Res> {
  __$$RegisterState_RegisteringImplCopyWithImpl(
      _$RegisterState_RegisteringImpl _value,
      $Res Function(_$RegisterState_RegisteringImpl) _then)
      : super(_value, _then);

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$RegisterState_RegisteringImpl extends RegisterState_Registering {
  const _$RegisterState_RegisteringImpl() : super._();

  @override
  String toString() {
    return 'RegisterState.registering()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterState_RegisteringImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int nextS) registered,
    required TResult Function() registering,
    required TResult Function(BigInt? retryWait, String error) failed,
  }) {
    return registering();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int nextS)? registered,
    TResult? Function()? registering,
    TResult? Function(BigInt? retryWait, String error)? failed,
  }) {
    return registering?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int nextS)? registered,
    TResult Function()? registering,
    TResult Function(BigInt? retryWait, String error)? failed,
    required TResult orElse(),
  }) {
    if (registering != null) {
      return registering();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RegisterState_Registered value) registered,
    required TResult Function(RegisterState_Registering value) registering,
    required TResult Function(RegisterState_Failed value) failed,
  }) {
    return registering(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RegisterState_Registered value)? registered,
    TResult? Function(RegisterState_Registering value)? registering,
    TResult? Function(RegisterState_Failed value)? failed,
  }) {
    return registering?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RegisterState_Registered value)? registered,
    TResult Function(RegisterState_Registering value)? registering,
    TResult Function(RegisterState_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (registering != null) {
      return registering(this);
    }
    return orElse();
  }
}

abstract class RegisterState_Registering extends RegisterState {
  const factory RegisterState_Registering() = _$RegisterState_RegisteringImpl;
  const RegisterState_Registering._() : super._();
}

/// @nodoc
abstract class _$$RegisterState_FailedImplCopyWith<$Res> {
  factory _$$RegisterState_FailedImplCopyWith(_$RegisterState_FailedImpl value,
          $Res Function(_$RegisterState_FailedImpl) then) =
      __$$RegisterState_FailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BigInt? retryWait, String error});
}

/// @nodoc
class __$$RegisterState_FailedImplCopyWithImpl<$Res>
    extends _$RegisterStateCopyWithImpl<$Res, _$RegisterState_FailedImpl>
    implements _$$RegisterState_FailedImplCopyWith<$Res> {
  __$$RegisterState_FailedImplCopyWithImpl(_$RegisterState_FailedImpl _value,
      $Res Function(_$RegisterState_FailedImpl) _then)
      : super(_value, _then);

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? retryWait = freezed,
    Object? error = null,
  }) {
    return _then(_$RegisterState_FailedImpl(
      retryWait: freezed == retryWait
          ? _value.retryWait
          : retryWait // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RegisterState_FailedImpl extends RegisterState_Failed {
  const _$RegisterState_FailedImpl({this.retryWait, required this.error})
      : super._();

  @override
  final BigInt? retryWait;
  @override
  final String error;

  @override
  String toString() {
    return 'RegisterState.failed(retryWait: $retryWait, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterState_FailedImpl &&
            (identical(other.retryWait, retryWait) ||
                other.retryWait == retryWait) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, retryWait, error);

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterState_FailedImplCopyWith<_$RegisterState_FailedImpl>
      get copyWith =>
          __$$RegisterState_FailedImplCopyWithImpl<_$RegisterState_FailedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int nextS) registered,
    required TResult Function() registering,
    required TResult Function(BigInt? retryWait, String error) failed,
  }) {
    return failed(retryWait, error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int nextS)? registered,
    TResult? Function()? registering,
    TResult? Function(BigInt? retryWait, String error)? failed,
  }) {
    return failed?.call(retryWait, error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int nextS)? registered,
    TResult Function()? registering,
    TResult Function(BigInt? retryWait, String error)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(retryWait, error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RegisterState_Registered value) registered,
    required TResult Function(RegisterState_Registering value) registering,
    required TResult Function(RegisterState_Failed value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RegisterState_Registered value)? registered,
    TResult? Function(RegisterState_Registering value)? registering,
    TResult? Function(RegisterState_Failed value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RegisterState_Registered value)? registered,
    TResult Function(RegisterState_Registering value)? registering,
    TResult Function(RegisterState_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class RegisterState_Failed extends RegisterState {
  const factory RegisterState_Failed(
      {final BigInt? retryWait,
      required final String error}) = _$RegisterState_FailedImpl;
  const RegisterState_Failed._() : super._();

  BigInt? get retryWait;
  String get error;

  /// Create a copy of RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterState_FailedImplCopyWith<_$RegisterState_FailedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TextFormat {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextFlags field0) flags,
    required TResult Function(TextEffect field0) effect,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextFlags field0)? flags,
    TResult? Function(TextEffect field0)? effect,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextFlags field0)? flags,
    TResult Function(TextEffect field0)? effect,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextFormat_Flags value) flags,
    required TResult Function(TextFormat_Effect value) effect,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextFormat_Flags value)? flags,
    TResult? Function(TextFormat_Effect value)? effect,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextFormat_Flags value)? flags,
    TResult Function(TextFormat_Effect value)? effect,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TextFormatCopyWith<$Res> {
  factory $TextFormatCopyWith(
          TextFormat value, $Res Function(TextFormat) then) =
      _$TextFormatCopyWithImpl<$Res, TextFormat>;
}

/// @nodoc
class _$TextFormatCopyWithImpl<$Res, $Val extends TextFormat>
    implements $TextFormatCopyWith<$Res> {
  _$TextFormatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TextFormat_FlagsImplCopyWith<$Res> {
  factory _$$TextFormat_FlagsImplCopyWith(_$TextFormat_FlagsImpl value,
          $Res Function(_$TextFormat_FlagsImpl) then) =
      __$$TextFormat_FlagsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({TextFlags field0});
}

/// @nodoc
class __$$TextFormat_FlagsImplCopyWithImpl<$Res>
    extends _$TextFormatCopyWithImpl<$Res, _$TextFormat_FlagsImpl>
    implements _$$TextFormat_FlagsImplCopyWith<$Res> {
  __$$TextFormat_FlagsImplCopyWithImpl(_$TextFormat_FlagsImpl _value,
      $Res Function(_$TextFormat_FlagsImpl) _then)
      : super(_value, _then);

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TextFormat_FlagsImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as TextFlags,
    ));
  }
}

/// @nodoc

class _$TextFormat_FlagsImpl extends TextFormat_Flags {
  const _$TextFormat_FlagsImpl(this.field0) : super._();

  @override
  final TextFlags field0;

  @override
  String toString() {
    return 'TextFormat.flags(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextFormat_FlagsImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextFormat_FlagsImplCopyWith<_$TextFormat_FlagsImpl> get copyWith =>
      __$$TextFormat_FlagsImplCopyWithImpl<_$TextFormat_FlagsImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextFlags field0) flags,
    required TResult Function(TextEffect field0) effect,
  }) {
    return flags(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextFlags field0)? flags,
    TResult? Function(TextEffect field0)? effect,
  }) {
    return flags?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextFlags field0)? flags,
    TResult Function(TextEffect field0)? effect,
    required TResult orElse(),
  }) {
    if (flags != null) {
      return flags(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextFormat_Flags value) flags,
    required TResult Function(TextFormat_Effect value) effect,
  }) {
    return flags(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextFormat_Flags value)? flags,
    TResult? Function(TextFormat_Effect value)? effect,
  }) {
    return flags?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextFormat_Flags value)? flags,
    TResult Function(TextFormat_Effect value)? effect,
    required TResult orElse(),
  }) {
    if (flags != null) {
      return flags(this);
    }
    return orElse();
  }
}

abstract class TextFormat_Flags extends TextFormat {
  const factory TextFormat_Flags(final TextFlags field0) =
      _$TextFormat_FlagsImpl;
  const TextFormat_Flags._() : super._();

  @override
  TextFlags get field0;

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextFormat_FlagsImplCopyWith<_$TextFormat_FlagsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TextFormat_EffectImplCopyWith<$Res> {
  factory _$$TextFormat_EffectImplCopyWith(_$TextFormat_EffectImpl value,
          $Res Function(_$TextFormat_EffectImpl) then) =
      __$$TextFormat_EffectImplCopyWithImpl<$Res>;
  @useResult
  $Res call({TextEffect field0});
}

/// @nodoc
class __$$TextFormat_EffectImplCopyWithImpl<$Res>
    extends _$TextFormatCopyWithImpl<$Res, _$TextFormat_EffectImpl>
    implements _$$TextFormat_EffectImplCopyWith<$Res> {
  __$$TextFormat_EffectImplCopyWithImpl(_$TextFormat_EffectImpl _value,
      $Res Function(_$TextFormat_EffectImpl) _then)
      : super(_value, _then);

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TextFormat_EffectImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as TextEffect,
    ));
  }
}

/// @nodoc

class _$TextFormat_EffectImpl extends TextFormat_Effect {
  const _$TextFormat_EffectImpl(this.field0) : super._();

  @override
  final TextEffect field0;

  @override
  String toString() {
    return 'TextFormat.effect(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextFormat_EffectImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextFormat_EffectImplCopyWith<_$TextFormat_EffectImpl> get copyWith =>
      __$$TextFormat_EffectImplCopyWithImpl<_$TextFormat_EffectImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextFlags field0) flags,
    required TResult Function(TextEffect field0) effect,
  }) {
    return effect(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextFlags field0)? flags,
    TResult? Function(TextEffect field0)? effect,
  }) {
    return effect?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextFlags field0)? flags,
    TResult Function(TextEffect field0)? effect,
    required TResult orElse(),
  }) {
    if (effect != null) {
      return effect(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextFormat_Flags value) flags,
    required TResult Function(TextFormat_Effect value) effect,
  }) {
    return effect(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextFormat_Flags value)? flags,
    TResult? Function(TextFormat_Effect value)? effect,
  }) {
    return effect?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextFormat_Flags value)? flags,
    TResult Function(TextFormat_Effect value)? effect,
    required TResult orElse(),
  }) {
    if (effect != null) {
      return effect(this);
    }
    return orElse();
  }
}

abstract class TextFormat_Effect extends TextFormat {
  const factory TextFormat_Effect(final TextEffect field0) =
      _$TextFormat_EffectImpl;
  const TextFormat_Effect._() : super._();

  @override
  TextEffect get field0;

  /// Create a copy of TextFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextFormat_EffectImplCopyWith<_$TextFormat_EffectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
